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

### Set the environment and launch

The `workbench` profile reads a few environment variables. Export them once per
shell (the project and Pet Service Account are auto-detected — do not hardcode
them):

```sh
export GOOGLE_CLOUD_PROJECT="$(wb status | grep 'Google project' | awk -F': ' '{print $2}' | xargs)"
export GOOGLE_SERVICE_ACCOUNT_EMAIL="$(wb auth status | grep 'Service account email' | awk -F': ' '{print $2}' | xargs)"
export NF_WORK_BUCKET="$(wb resource resolve --name=nf-scratch | xargs)"   # gs:// URL
export NF_REGION="us-central1"                                             # match the bucket

nextflow run main.nf \
  -profile workbench \
  --outdir "${NF_WORK_BUCKET}/hello-nf-on-wb/results"
```

If `NF_WORK_BUCKET` comes back empty, run `wb resource list` to refresh the
workspace context cache, then re-export.

Each `sayHello`/`convertToUpper` task becomes an independent Google Batch job.
Watch them in the [Batch console](https://console.cloud.google.com/batch/jobs) or
with `gcloud batch jobs list`. Add `-resume` to reuse cached tasks. Delete
`${NF_WORK_BUCKET}/hello-nf-on-wb/scratch` when you no longer need to
`-resume`.

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
| `google.project` | `GOOGLE_CLOUD_PROJECT` | Workspace GCP project |
| `google.location` | `NF_REGION` | Where Batch VMs run |
| `google.batch.serviceAccountEmail` | `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Workbench Pet SA |
| `workDir` | `NF_WORK_BUCKET` | GCS staging for tasks |
| `network` / `subnetwork` + `usePrivateAddress` | fixed | Workbench VPC; private VMs, NAT egress |
| `process.container` | `NF_CONTAINER` (optional) | Task image |

## See also

- Run an nf-core pipeline on Workbench:
  [`../nf-core-workbench-profile/`](../nf-core-workbench-profile/README.md).
- Convert a pipeline whose source code assumes local/HPC execution:
  [`nextflow-to-workbench` skill](../../claude/skills/nextflow-to-workbench/SKILL.md).
- Background talk: [Nextflow on Workbench slide outline](../nextflow-on-workbench-slides.md).
