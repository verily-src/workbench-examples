# hello-nf-on-wb

A minimal [Nextflow](https://www.nextflow.io) pipeline, in the style of the
official [Nextflow "Hello" training](https://training.nextflow.io/hello_nextflow/),
that runs **unchanged** on your laptop or on Verily Workbench via
[Google Batch](https://www.nextflow.io/docs/latest/google.html#cloud-batch).

The pipeline reads greetings from a CSV, writes each to its own file, uppercases
them in parallel, and collects them into one file. The string processing is
beside the point — the example exists to show the parts that make a pipeline
**Workbench-ready**: profiles, a params file, containers, and a GCS work
directory.

New to Nextflow? Do the [Hello Nextflow training](https://training.nextflow.io/hello_nextflow/)
first; this example mirrors its structure.

## Layout

```
hello-nf-on-wb/
├── main.nf              # the workflow (executor-agnostic)
├── nextflow.config      # params + profiles: standard, docker, workbench
├── test-params.yaml     # example inputs
├── data/
│   └── greetings.csv    # pipeline input
└── modules/
    ├── sayHello.nf
    ├── convertToUpper.nf
    └── collectGreetings.nf
```

## Run it locally

No Workbench, no setup — just Nextflow:

```sh
nextflow run main.nf -profile standard
```

The collected result is written to `results/COLLECTED-greetings.txt`. You can pass
inputs with a params file or on the command line:

```sh
nextflow run main.nf -profile standard -params-file test-params.yaml
nextflow run main.nf -profile standard --input data/greetings.csv
```

To run the same thing inside a container (requires Docker):

```sh
nextflow run main.nf -profile docker
```

## Run it on Verily Workbench (Google Batch)

### One-time workspace setup

From a Workbench cloud environment (JupyterLab) in a workspace where you are an
Owner/Admin:

```sh
# A GCS bucket resource for the work directory and outputs.
wb resource create gcs-bucket --id=nf-scratch

# Point the wb CLI at your workspace so it can auto-detect project + service account.
wb workspace set --id=<your-workspace-id>
```

Workbench manages the rest (the `network`/`subnetwork` VPC, Cloud NAT, required
APIs, and the Pet Service Account's IAM roles) — you do not create those.

### Stage your input data

Real pipelines read inputs from a bucket, not the Git repo — production data is
often gigabytes and never lives beside the code. Upload the sample CSV (a
stand-in for your real data) to your workspace bucket:

```sh
export NF_WORK_BUCKET="$(wb resource resolve --name=nf-scratch | xargs)"   # gs:// URL
export NF_REGION="us-central1"                                             # match the bucket

gcloud storage cp data/greetings.csv "${NF_WORK_BUCKET}/inputs/greetings.csv"
```

### Launch

Use the `wb nextflow` wrapper. It auto-sets `GOOGLE_CLOUD_PROJECT` and
`GOOGLE_SERVICE_ACCOUNT_EMAIL` for you (do not hardcode them); you pass the
`gs://` input and output:

```sh
wb nextflow run main.nf \
  -profile workbench \
  --input  "${NF_WORK_BUCKET}/inputs/greetings.csv" \
  --outdir "${NF_WORK_BUCKET}/hello-nf-on-wb/results"
```

Use `wb nextflow` (not plain `nextflow`): it is what makes `logsPath` and the
Workbench environment variables resolve. If `NF_WORK_BUCKET` comes back empty,
run `wb resource list` to refresh the workspace context cache, then re-export.

Each `sayHello`/`convertToUpper` task becomes an independent Google Batch job.
Watch them in the [Batch console](https://console.cloud.google.com/batch/jobs) or
with `gcloud batch jobs list`. Add `-resume` to reuse cached tasks. Delete
`${NF_WORK_BUCKET}/hello-nf-on-wb/scratch` when you no longer need to
`-resume`.

> **Zero-setup smoke test.** Omit `--input` and the pipeline falls back to the
> bundled `data/greetings.csv` (its `projectDir`-anchored default), letting you
> confirm the Workbench wiring end-to-end before staging any data. For real work,
> always pass a `gs://` `--input` — a bare relative path resolves against the
> orchestrator's launch directory (not the pipeline) and fails with
> `No such file or directory`.

### Run from the Workbench UI

You can also register this pipeline under **Workflows** from its Git repo (set the
main script to `nextflow/hello-nf-on-wb/main.nf`, profile `workbench`).

Stage your data to the bucket (above), then supply a params file with `gs://`
paths. A params file is read verbatim and the run launches from a non-pipeline
directory, so a relative `input` will **not** resolve (see the commented example
in `test-params.yaml`):

```yaml
input:  "gs://<your-bucket>/inputs/greetings.csv"
outdir: "gs://<your-bucket>/hello-nf-on-wb/results"
```

To just smoke-test the wiring, register and run with profile `workbench` and no
params file — the bundled sample is used.

### Optional: a pinned container from Artifact Registry

This example runs on the public `debian:stable-slim` image, so no build is
required. For a real pipeline, push a pinned image to
[Artifact Registry](https://cloud.google.com/artifact-registry) and point the
profile at it:

```sh
export NF_CONTAINER="us-central1-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/<repo>/<image>:<tag>"
```

## How the `workbench` profile works

All Workbench/GCP wiring is the `workbench` profile in `nextflow.config`, driven
entirely by environment variables (12-Factor config), so nothing workspace-
specific is committed:

| Setting | Source | Purpose |
| --- | --- | --- |
| `process.executor = 'google-batch'` | fixed | Run each task as a Batch job |
| `process.machineType` | fixed | Explicit VM size (Batch does not autosize) |
| `google.project` | `GOOGLE_CLOUD_PROJECT` | Workspace GCP project |
| `google.location` | `NF_REGION` | Where Batch VMs run |
| `google.batch.serviceAccountEmail` | `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Workbench Pet SA |
| `workDir` | `NF_WORK_BUCKET` | GCS staging for tasks |
| `logsPath` | `NF_WORK_BUCKET` | Workflow logs to the bucket (via `wb nextflow`) |
| `network` / `subnetwork` + `usePrivateAddress` | fixed | Workbench VPC; private VMs, NAT egress |
| `process.container` | `NF_CONTAINER` (optional) | Task image |

This profile mirrors the
[Workbench support docs example](https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/).
It uses `env('VAR')` for portability. The docs' native alternative is to
reference a bucket by its Workbench resource name directly — e.g.
`workDir = '$WORKBENCH_nf-scratch/scratch'` — which the `wb nextflow` wrapper
expands at launch. Either style works under `wb nextflow`.

## See also

- Run an nf-core pipeline on Workbench:
  [`../nf-core-workbench-profile/`](../nf-core-workbench-profile/README.md).
- Convert a pipeline whose source code assumes local/HPC execution:
  [`nextflow-to-workbench` skill](../../claude/skills/nextflow-to-workbench/SKILL.md).
- Background talk: [Nextflow on Workbench slide outline](../nextflow-on-workbench-slides.md).
