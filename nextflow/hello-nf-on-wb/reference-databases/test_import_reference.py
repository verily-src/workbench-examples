"""Offline checks for import integrity and cloud writes, with wb/gcloud mocked."""

import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

import import_reference as importer


class ReferenceImportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.directory = self.root / "download"
        data = Path(__file__).parent / "data"
        self.contents = {
            "reference.fasta": (data / "tiny.fasta").read_bytes(),
            "annotations.csv": (data / "tiny.csv").read_bytes(),
        }
        self.manifest = {
            "schema_version": 1, "database": "MEGARes", "version": "0.0.0",
            "files": {name: {"url": f"https://example.org/{name}",
                             "sha256": hashlib.sha256(content).hexdigest()}
                      for name, content in self.contents.items()},
        }
        self.manifest_path = self.root / "manifest.json"
        self.write_manifest()
        self.args = argparse.Namespace(directory=self.directory, manifest=self.manifest_path,
                                       bucket_resource="nf-data", prefix="references")

    def write_manifest(self):
        self.manifest_path.write_bytes(importer.json_bytes(self.manifest))

    def fetch(self):
        def response(request, timeout):
            name = request.full_url.rsplit("/", 1)[-1]
            stream = io.BytesIO(self.contents[name])
            stream.geturl = lambda: request.full_url
            return stream
        with patch.object(importer, "build_opener") as opener:
            opener.return_value.open.side_effect = response
            importer.fetch(self.args)

    def test_fetch_records_verified_pair(self):
        self.fetch()
        receipt = json.loads((self.directory / "provenance.json").read_text())
        self.assertEqual(receipt["manifest"], self.manifest)
        self.assertEqual(receipt["files"]["reference.fasta"]["bases"], 16)
        self.assertEqual(receipt["files"]["annotations.csv"]["rows"], 2)

    def test_checksum_failure_leaves_no_download(self):
        self.contents["reference.fasta"] += b"A\n"
        with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
            self.fetch()
        self.assertFalse(self.directory.exists())

    def test_mismatched_pair_is_rejected_even_with_correct_hashes(self):
        self.contents["annotations.csv"] = self.contents["annotations.csv"].replace(b"TEST000001.1", b"OTHER00001.1")
        self.manifest["files"]["annotations.csv"]["sha256"] = hashlib.sha256(self.contents["annotations.csv"]).hexdigest()
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "headers do not match"):
            self.fetch()
        self.assertFalse(self.directory.exists())

    def test_invalid_url_and_manifest_file_names_are_rejected(self):
        for url in ("http://example.org/data", "file:///tmp/data", "https://user:secret@example.org/data"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                importer.validate_url(url)
        self.manifest["files"]["../reference.fasta"] = self.manifest["files"].pop("reference.fasta")
        self.write_manifest()
        with self.assertRaises(ValueError):
            importer.read_manifest(self.manifest_path)

    def test_modified_local_reference_never_calls_cloud_tools(self):
        self.fetch()
        (self.directory / "reference.fasta").write_bytes(b">changed\nACGT\n")
        with patch.object(importer.subprocess, "run") as run:
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                importer.upload(self.args)
            run.assert_not_called()

    def test_upload_is_retryable_and_produces_params_only_after_success(self):
        self.fetch()
        objects, calls = {}, []
        fail_annotations = True

        def cloud(command, **kwargs):
            calls.append(command)
            if command[0] == "wb":
                return subprocess.CompletedProcess(command, 0, "gs://test-workbench-bucket\n", "")
            if command[2] == "cp":
                source, destination = Path(command[3]), command[4]
                self.assertIn("--if-generation-match=0", command)
                if destination in objects or (source.name == "annotations.csv" and fail_annotations):
                    return subprocess.CompletedProcess(command, 1, "", "precondition or simulated network failure")
                objects[destination] = source.read_bytes()
                return subprocess.CompletedProcess(command, 0, "", "")
            destination = command[4]
            if destination not in objects:
                return subprocess.CompletedProcess(command, 1, "", "not found")
            digest = base64.b64encode(hashlib.md5(objects[destination]).digest()).decode()
            return subprocess.CompletedProcess(command, 0, digest + "\n", "")

        with patch.object(importer.subprocess, "run", side_effect=cloud):
            with self.assertRaisesRegex(ValueError, "Upload failed"):
                importer.upload(self.args)
            self.assertFalse((self.directory / "params.workbench.json").exists())
            fail_annotations = False
            importer.upload(self.args)
            importer.upload(self.args)  # Same receipt is safe to retry after success too.
        params = json.loads((self.directory / "params.workbench.json").read_text())
        self.assertEqual(len(objects), 4)
        self.assertTrue(params["reference"].startswith("gs://test-workbench-bucket/references/megares/0.0.0/"))
        self.assertTrue(params["annotations"].endswith("/annotations.csv"))
        self.assertEqual(calls[0], ["wb", "resource", "resolve", "--name=nf-data"])

    def test_existing_different_object_is_not_treated_as_success(self):
        path = self.root / "data"
        path.write_bytes(b"correct")
        failure = subprocess.CompletedProcess([], 1, "", "object exists")
        mismatch = subprocess.CompletedProcess([], 0, "wrong-md5", "")
        with patch.object(importer.subprocess, "run", side_effect=[failure, mismatch]):
            with self.assertRaisesRegex(ValueError, "different content"):
                importer.checked_upload(path, "gs://test-bucket/object")

    def test_malformed_fasta_is_rejected(self):
        for data in (b"<html>Error</html>", b">empty\n", b"ACGT\n", b">one\nACGT\n>empty\n"):
            with self.subTest(data=data), self.assertRaises(ValueError):
                importer.summarize(data)


if __name__ == "__main__":
    unittest.main()
