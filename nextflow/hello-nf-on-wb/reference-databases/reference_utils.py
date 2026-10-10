#!/usr/bin/env python3
"""Validate and summarize a small nucleotide FASTA without third-party packages."""

import hashlib
import csv
import io
import json
from pathlib import Path
import re
import sys


MAX_BYTES = 10 * 1024 * 1024


def summarize(data, expected_sha256=None):
    if not data or len(data) > MAX_BYTES:
        raise ValueError("Expected a nonempty FASTA no larger than 10 MiB")
    digest = hashlib.sha256(data).hexdigest()
    if expected_sha256 is not None:
        if not re.fullmatch(r"[a-fA-F0-9]{64}", expected_sha256):
            raise ValueError("SHA-256 must contain exactly 64 hexadecimal characters")
        if digest != expected_sha256.lower():
            raise ValueError(f"SHA-256 mismatch: expected {expected_sha256}, received {digest}")
    headers, bases, record_bases = [], 0, 0
    for line in data.decode("ascii").splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith(">"):
            if len(line) == 1 or (headers and not record_bases):
                raise ValueError("FASTA records need a header and a sequence")
            headers.append(line[1:])
            record_bases = 0
        else:
            if not headers or not re.fullmatch(r"[ACGTURYSWKMBDHVNacgturyswkmbdhvn]+", line):
                raise ValueError("Expected nucleotide FASTA, not an error page or another file format")
            bases += len(line)
            record_bases += len(line)
    if not headers or not record_bases:
        raise ValueError("FASTA records need a header and a sequence")
    return {"sha256": digest, "bytes": len(data), "sequences": len(headers), "bases": bases}


def check_annotations(data, fasta_data, expected_sha256):
    digest = hashlib.sha256(data).hexdigest()
    if not re.fullmatch(r"[a-fA-F0-9]{64}", expected_sha256) or digest != expected_sha256.lower():
        raise ValueError("Annotation SHA-256 mismatch")
    reader = csv.DictReader(io.StringIO(data.decode("utf-8")))
    if reader.fieldnames != ["header", "type", "class", "mechanism", "group", "snp"]:
        raise ValueError("Expected the MEGARes annotation CSV columns")
    rows = list(reader)
    headers = [line[1:] for line in fasta_data.decode("ascii").splitlines() if line.startswith(">")]
    if len(rows) != len(headers) or {row["header"] for row in rows} != set(headers):
        raise ValueError("MEGARes FASTA and annotation headers do not match")
    return {"sha256": digest, "bytes": len(data), "rows": len(rows)}


if __name__ == "__main__":
    try:
        data = Path(sys.argv[1]).read_bytes()
        result = summarize(data, expected_sha256=sys.argv[2])
        result["annotations"] = check_annotations(Path(sys.argv[3]).read_bytes(), data, sys.argv[4])
        print(json.dumps(result, indent=2, sort_keys=True))
    except (ValueError, OSError) as exc:
        sys.exit(str(exc))
