#!/usr/bin/env python3
"""Fetch the pinned MEGARes FASTA/annotation pair, then import it into Workbench."""

import argparse
import base64
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from reference_utils import MAX_BYTES, summarize, check_annotations

DEFAULT_MANIFEST = Path(__file__).with_name("megares-3.0.0.json")


def validate_url(url):
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.fragment or any(c.isspace() for c in url)):
        raise ValueError("Use a public HTTPS download URL without credentials, whitespace, or a fragment")
    return url


def read_manifest(path):
    manifest = json.loads(path.read_text())
    if (manifest.get("schema_version") != 1 or manifest.get("database") != "MEGARes"
            or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", manifest.get("version", ""))
            or set(manifest.get("files", {})) != {"reference.fasta", "annotations.csv"}):
        raise ValueError("Expected a versioned MEGARes FASTA/annotation manifest")
    for entry in manifest["files"].values():
        validate_url(entry["url"])
        if not re.fullmatch(r"[a-f0-9]{64}", entry["sha256"]):
            raise ValueError("Every manifest file needs an expected SHA-256")
    return manifest


def check_pair(contents, manifest):
    reference = contents["reference.fasta"]
    return {
        "reference.fasta": summarize(reference, manifest["files"]["reference.fasta"]["sha256"]),
        "annotations.csv": check_annotations(contents["annotations.csv"], reference,
                                             manifest["files"]["annotations.csv"]["sha256"]),
    }


class HttpsRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, new_url):
        validate_url(new_url)
        return super().redirect_request(request, fp, code, msg, headers, new_url)


def json_bytes(value):
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode()


def fetch(args):
    manifest = read_manifest(args.manifest)
    directory = args.directory.resolve()
    if directory.exists():
        raise ValueError(f"Directory already exists: {directory}; reuse it for upload or choose a new directory")
    contents, resolved_urls = {}, {}
    for name, entry in manifest["files"].items():
        request = Request(entry["url"], headers={"User-Agent": "hello-nf-on-wb-reference-example/1.0"})
        with build_opener(HttpsRedirects()).open(request, timeout=60) as response:
            resolved_urls[name] = validate_url(response.geturl())
            contents[name] = response.read(MAX_BYTES + 1)
        if len(contents[name]) > MAX_BYTES:
            raise ValueError("This MEGARes example accepts files no larger than 10 MiB")
    stats = check_pair(contents, manifest)
    receipt = {
        "schema_version": 1,
        "manifest": manifest,
        "resolved_urls": resolved_urls,
        "retrieved_at": datetime.now(timezone.utc).isoformat(),
        "files": stats,
    }
    # Make the receipt and data visible together only after all validation passes.
    with tempfile.TemporaryDirectory(dir=directory.parent) as temporary:
        staged = Path(temporary) / "reference"
        staged.mkdir()
        for name, data in contents.items():
            (staged / name).write_bytes(data)
        (staged / "provenance.json").write_bytes(json_bytes(receipt))
        staged.rename(directory)
    print(f"Fetched MEGARes {manifest['version']}: {stats['reference.fasta']['sequences']} sequences")
    print(f"Provenance: {directory / 'provenance.json'}")


def checked_upload(path, destination):
    """Never replace an object. An identical prior upload is safe to reuse."""
    copied = subprocess.run([
        "gcloud", "storage", "cp", str(path), destination, "--if-generation-match=0",
    ], capture_output=True, text=True)
    if copied.returncode == 0:
        return
    # This also makes a partial upload retryable using the same local receipt.
    existing = subprocess.run([
        "gcloud", "storage", "objects", "describe", destination,
        "--raw", "--format=value(md5Hash)",
    ], capture_output=True, text=True)
    local_md5 = base64.b64encode(hashlib.md5(path.read_bytes()).digest()).decode()
    if existing.returncode == 0 and existing.stdout.strip() == local_md5:
        return
    raise ValueError(f"Upload failed or destination has different content: {destination}\n{copied.stderr.strip()}")


def upload(args):
    directory = args.directory.resolve()
    receipt_path = directory / "provenance.json"
    receipt = json.loads(receipt_path.read_text())
    manifest = read_manifest(args.manifest)
    if receipt.get("schema_version") != 1 or receipt.get("manifest") != manifest:
        raise ValueError("Fetch receipt does not match the selected manifest")
    stats = check_pair({name: (directory / name).read_bytes() for name in manifest["files"]}, manifest)
    if receipt.get("files") != stats:
        raise ValueError("Reference no longer matches its provenance receipt")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", args.bucket_resource):
        raise ValueError("Invalid Workbench bucket resource name")
    if not re.fullmatch(r"[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*", args.prefix):
        raise ValueError("Prefix must contain simple directory names, without gs:// or traversal")
    resolved = subprocess.run([
        "wb", "resource", "resolve", f"--name={args.bucket_resource}",
    ], check=True, capture_output=True, text=True)
    bucket = resolved.stdout.strip().rstrip("/")
    if not re.fullmatch(r"gs://[a-z0-9][a-z0-9._-]{1,220}[a-z0-9]", bucket):
        raise ValueError("wb must resolve the resource to one gs:// bucket URI; check the current workspace")
    version = manifest["version"]
    digest = hashlib.sha256(json_bytes(manifest)).hexdigest()
    destination = f"{bucket}/{args.prefix}/megares/{version}/{digest}"
    params = {
        "reference": f"{destination}/reference.fasta",
        "reference_sha256": stats["reference.fasta"]["sha256"],
        "annotations": f"{destination}/annotations.csv",
        "annotations_sha256": stats["annotations.csv"]["sha256"],
        "outdir": f"{bucket}/hello-nf-on-wb/reference-results/megares-{version}/{digest[:12]}",
    }
    with tempfile.TemporaryDirectory() as temporary:
        params_path = Path(temporary) / "params.workbench.json"
        params_path.write_bytes(json_bytes(params))
        for path in (directory / "reference.fasta", directory / "annotations.csv", receipt_path, params_path):
            checked_upload(path, f"{destination}/{path.name}")
        # No local success params are produced until every cloud object succeeds.
        (directory / params_path.name).write_bytes(params_path.read_bytes())
    print(f"Imported reference and provenance: {destination}")
    print(f"UI params file: {destination}/params.workbench.json")
    print(f"Local params file: {directory / 'params.workbench.json'}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    download = commands.add_parser("fetch", help="Download and validate locally; no cloud access")
    download.add_argument("--directory", required=True, type=Path, help="New directory in an existing parent")
    download.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    send = commands.add_parser("upload", help="Verify a fetch receipt, resolve a bucket, and upload")
    send.add_argument("--directory", required=True, type=Path)
    send.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    send.add_argument("--bucket-resource", required=True, help="Workbench resource name, not physical bucket name")
    send.add_argument("--prefix", default="references", help="Destination folder within the resolved bucket")
    args = parser.parse_args()
    try:
        {"fetch": fetch, "upload": upload}[args.command](args)
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"error: {exc}\n")


if __name__ == "__main__":
    main()
