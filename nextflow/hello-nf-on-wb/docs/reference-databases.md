# Import MEGARes into a Workbench bucket

This example imports the **MEGARes 3.0.0 antimicrobial resistance database** and
its matching annotations, then runs a Nextflow task against the imported files.
FloRes uses this pair through its `amr` and `annotation` parameters. MEGARes
contains curated resistance sequences for drugs, biocides, and metals.
[Publisher description](https://www.meglab.org/megares/)

The pinned pair has 8,733 sequences (9,014,529 bases): a 9,608,076-byte FASTA and
a 1,074,138-byte annotation CSV. These counts and hashes were checked against
the files bundled in FloRes and the matching Git blobs in the
[publisher's AMR++ repository](https://github.com/Microbial-Ecology-Group/AMRplusplus/tree/b61577989f1f5b39888737301737e46f56432708/data/amr).
The full database stays outside this example's Git repository.

## 1. Fetch and verify the database locally

Run commands from `nextflow/hello-nf-on-wb`. You need Python 3; uploading later
also needs an authenticated `wb` and `gcloud` session with access to a Workbench
bucket resource. Use the bucket setup in the [main README](../README.md).

```sh
python3 reference-databases/import_reference.py fetch \
  --directory /tmp/megares-3.0.0
```

The helper reads [megares-3.0.0.json](../reference-databases/megares-3.0.0.json),
downloads the two versioned files from the
[official download page](https://www.meglab.org/megares/download/), verifies both
SHA-256 checksums, and checks that every FASTA header has a matching annotation.
It creates three local files:

```text
/tmp/megares-3.0.0/
├── reference.fasta
├── annotations.csv
└── provenance.json
```

The provenance receipt contains the manifest, original and resolved source URLs,
release, download time, byte counts, checksums, and sequence/annotation counts.
The helper rejects invalid FASTA, mismatched annotations, changed bytes, HTTP
downloads, and redirects away from HTTPS. It never executes downloaded content.
An existing local directory is preserved: reuse it for upload, or choose a new
directory for a fresh fetch.

The SHA-256 pins were calculated from files matching the publisher Git blobs
recorded in the manifest; they are **not publisher-signed checksums**. If a
download fails the checksum, inspect the source and release before updating the
manifest. A change in line endings also changes the checksum.

## 2. Import into your workspace

Select your workspace with `wb workspace set --id='<workspace-id>'`, then import
into an existing bucket resource:

```sh
python3 reference-databases/import_reference.py upload \
  --directory /tmp/megares-3.0.0 \
  --bucket-resource nf-scratch
```

This command performs the cloud writes. It resolves the resource using
`wb resource resolve --name=nf-scratch`, rechecks the local pair against the
manifest and receipt, then uploads under:

```text
<resolved-bucket>/references/megares/3.0.0/<manifest-sha256>/
├── reference.fasta
├── annotations.csv
├── provenance.json
└── params.workbench.json
```

The generated params file contains concrete `gs://` input and output paths for
this workspace. It is also saved locally after every upload succeeds. Generate
it again for each workspace; committed files contain no physical bucket names.

Uploads use a
[generation precondition](https://docs.cloud.google.com/storage/docs/request-preconditions)
to avoid replacing existing objects. After a partial failure, rerun `upload`
with the same local directory; already uploaded objects are reused only when
their stored MD5 matches the local bytes. Different existing content stops the
import. A new fetch has a new provenance timestamp; to keep both imports, use a
new folder with `--prefix references-review`.

## 3. Run the reference staging example

For an offline smoke test, run the included synthetic two-record fixture:

```sh
nextflow run reference-databases/main.nf -profile standard
```

It produces `results/reference-databases/reference-summary.json` with 2
sequences, 16 bases, and 2 annotation rows. This local profile needs `python3`.
The `docker` profile supplies Python using `python:3.12-slim`.

For the imported MEGARes database, use the generated parameters:

```sh
export NF_WORK_BUCKET="$(wb resource resolve --name=nf-scratch | xargs)"

wb nextflow run reference-databases/main.nf -profile workbench \
  -params-file /tmp/megares-3.0.0/params.workbench.json
```

In the Workflows UI, register this repository with main script
`nextflow/hello-nf-on-wb/reference-databases/main.nf` and profile `workbench`.
In the params-file picker, select the bucket resource and the
`references/megares/3.0.0/<manifest-sha256>/params.workbench.json` file printed by
the importer. Use the UI-managed work directory as in the main example.

The result is `reference-summary.json` under the generated `outdir`. Expect
8,733 sequences, 9,014,529 bases, and 8,733 annotation rows, with hashes matching
the manifest.

The key pattern in [main.nf](../reference-databases/main.nf) is:

```nextflow
input:
path reference, name: 'reference.fasta', arity: '1'
path annotations, name: 'annotations.csv', arity: '1'
```

Nextflow stages both `gs://` objects as local task files. The Python command
reads `reference.fasta` and `annotations.csv`; it does not download reference
data itself. The task verifies both checksums and matching annotation headers
after staging. [Nextflow file inputs](https://docs.seqera.io/nextflow/process#input-files-path)

## Reuse the imported pair with FloRes

Map the generated values to FloRes parameters:

| This example | FloRes parameter | Meaning |
| --- | --- | --- |
| `reference` | `amr` | MEGARes FASTA |
| `annotations` | `annotation` | Matching MEGARes CSV |

Keep both files on the same release. For a FloRes run, supply its other required
parameters and configure its indexing step for the imported FASTA; an existing
index for another reference is not interchangeable. This example demonstrates
import and task staging, rather than running the full FloRes analysis.

Kraken2/Bracken databases, host genomes, and QIIME2 classifiers are separate
FloRes inputs. This helper deliberately handles only a MEGARes FASTA/CSV pair
(up to 10 MiB per file); it does not unpack large classifier archives.

## Provenance and local verification

Database attribution: Bonin et al., *MEGARes and AMR++, v3.0*,
[doi:10.1093/nar/gkac1047](https://doi.org/10.1093/nar/gkac1047).
The publisher's AMR++ repository provides its
[license](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/b61577989f1f5b39888737301737e46f56432708/LICENSE);
database source links and publisher identifiers remain in the import receipt.

Offline checks cover checksum rejection, malformed inputs, matching annotations,
bucket resolution, upload failures, and safe retries using mocked cloud commands:

```sh
python3 -m unittest discover -s reference-databases -p 'test_*.py'
```

Workbench validation: fetch and import the full pair, select its generated params
in the UI, and confirm the counts and checksums above in the published summary.
