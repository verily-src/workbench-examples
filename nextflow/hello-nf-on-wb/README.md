# hello-nf-on-wb

A minimal [Nextflow](https://www.nextflow.io) pipeline, in the style of the
official [Nextflow "Hello" training](https://training.nextflow.io/hello_nextflow/),
that runs unchanged on your laptop or on Verily Workbench via
[Google Batch](https://www.nextflow.io/docs/latest/google.html#cloud-batch).

The pipeline reads greetings from a CSV, writes each to its own file, uppercases
them in parallel, and collects them into one file. The string processing itself
does not matter. The example is here to show the parts that make a pipeline
Workbench-ready: profiles, a params file, containers, and a GCS work directory.

New to Nextflow? Start with the
[Hello Nextflow training](https://training.nextflow.io/hello_nextflow/); this
example mirrors its structure.

## Layout

```
hello-nf-on-wb/
├── main.nf              # the workflow (executor-agnostic)
├── nextflow.config      # params + profiles: standard, docker, verily_workbench
├── test-params.yaml     # example inputs
├── data/
│   └── greetings.csv    # pipeline input
└── modules/
    ├── sayHello.nf
    ├── convertToUpper.nf
    └── collectGreetings.nf
```

## 1. Run it locally

No Workbench and no setup, just Nextflow:

```sh
nextflow run main.nf -profile standard
```

The collected result is written to `results/COLLECTED-greetings.txt`. You can pass
inputs with a params file or on the command line:

```sh
nextflow run main.nf -profile standard -params-file test-params.yaml
nextflow run main.nf -profile standard --input data/greetings.csv
```

## 2. Run it locally with Docker

The same pipeline, run inside a container. Docker must be running:

```sh
nextflow run main.nf -profile docker
```

## 3. Run it on Workbench (UI / Workflows)

The Workflows UI is the main way to run this pipeline on Workbench. The pipeline
code is identical to the local runs; only how you supply parameters changes.

### Reference buckets by resource, not by name

A Workbench bucket has two names: a resource ID you choose (`<resource-id>`) and a
physical name with a workspace-specific suffix (`<resource-id>-wb-<workspace>`).
The physical name is not portable to other workspaces, so it must never appear in
committed pipeline code. Instead:

- `input` defaults to the bundled sample (resolved via `projectDir`), so a first
  run needs no data staging.
- `outdir` and `work_dir` have no cloud default, so you pass `gs://` paths at run
  time. On `-profile verily_workbench` the pipeline fails fast if either is not a
  `gs://` path, because a relative path is written to the ephemeral orchestrator
  disk and lost.
- You get the `gs://` path by resolving the resource, so the only
  workspace-specific token anywhere is the resource ID you created:
  `wb resource resolve --name=<your-bucket-resource>`.

### One-time workspace setup

From a Workbench cloud environment in a workspace where you are an Owner/Admin:

```sh
wb resource create gcs-bucket --id=<your-bucket-resource-id>   # bucket for work dir + outputs
wb workspace set --id=<your-workspace-id>                       # so wb can auto-detect context
```

Workbench manages the rest: the `network`/`subnetwork` VPC, Cloud NAT, required
APIs, and the Pet Service Account's IAM roles.

### Register and run

Register the pipeline under Workflows from its Git repo (main script
`nextflow/hello-nf-on-wb/main.nf`, profile `verily_workbench`).

The UI's params-file picker lists JSON/YAML files from a bucket resource, not the
Git repo, so create a params file and upload it. A params file is read verbatim,
so its paths must be `gs://`. For a minimal run, set `outdir` and let the pipeline
use the bundled input (`workDir` is set for you by the UI):

```sh
RES=<your-bucket-resource-id>                          # the gcs-bucket resource you created
BUCKET="$(wb resource resolve --name="$RES" | xargs)"  # -> gs://...
printf 'outdir: "%s/hello-nf-on-wb/results"\n' "$BUCKET" > params.verily_workbench.yaml
gcloud storage cp params.verily_workbench.yaml "$BUCKET/params/params.verily_workbench.yaml"
```

Then in **Set up parameters**, choose your bucket resource and select
`params/params.verily_workbench.yaml`.

To use your own data, stage the CSV to the bucket and add an `input:` line to the
params file:

```sh
gcloud storage cp data/greetings.csv "$BUCKET/inputs/greetings.csv"
# then add to params.verily_workbench.yaml:
#   input: "<gs path printed by the command above>/inputs/greetings.csv"
```

### Where results and logs go

- Results: your `outdir`, the durable output, e.g.
  `<bucket>/hello-nf-on-wb/results/COLLECTED-greetings.txt`. This is the only
  place to look for results.
- Work dir: scratch, under `<bucket>/…_job_<timestamp>/<run-id>/<hash>/` folders
  (UI-managed on the UI path). Nextflow also leaves a copy of each task's outputs
  here, so do not mistake it for your results. You can delete it after a
  successful run unless you plan to `-resume`.
- Logs: the job's Logs tab in the UI, the `nextflow.log` in the work dir, or Cloud
  Logging. Watch running jobs in the
  [Batch console](https://console.cloud.google.com/batch/jobs) or with
  `gcloud batch jobs list`.

## 4. Run it on Workbench (CLI) — optional

The same pipeline runs from the CLI with `wb nextflow`, for example from an app
terminal. It uses the one-time setup and the bucket rule from section 3.

`wb nextflow` injects `GOOGLE_CLOUD_PROJECT` and `GOOGLE_SERVICE_ACCOUNT_EMAIL`
for you. Resolve your bucket resource once, then pass the work and output dirs as
params. The bundled sample is used as input and results land in your bucket:

```sh
RES=<your-bucket-resource-id>                          # the gcs-bucket resource you created
BUCKET="$(wb resource resolve --name="$RES" | xargs)"  # -> gs://...

wb nextflow run main.nf -profile verily_workbench \
  --work_dir "$BUCKET/scratch" \
  --outdir   "$BUCKET/hello-nf-on-wb/results"
```

To run against your own data, stage it to the bucket and point `--input` at it:

```sh
gcloud storage cp data/greetings.csv "$BUCKET/inputs/greetings.csv"

wb nextflow run main.nf -profile verily_workbench \
  --input    "$BUCKET/inputs/greetings.csv" \
  --work_dir "$BUCKET/scratch" \
  --outdir   "$BUCKET/hello-nf-on-wb/results"
```

If `BUCKET` comes back empty, run `wb resource list` to refresh the workspace
context cache, then re-resolve.

## Optional: a pinned container from Artifact Registry

This example runs on the public `debian:stable-slim` image, so no build is
required. For a real pipeline, push a pinned image to
[Artifact Registry](https://cloud.google.com/artifact-registry) and pass it as
the `container` param:

```sh
--container "us-central1-docker.pkg.dev/<project>/<repo>/<image>:<tag>"
```

## How the `verily_workbench` profile works

The `verily_workbench` profile in `nextflow.config` holds all the Google Batch
wiring. Everything you control is a **param** (so it works the same on the CLI and
in the UI); only the project and service account are read from the environment,
because Workbench injects those automatically on both paths. Nothing
workspace-specific is committed. It mirrors the
[Workbench support docs example](https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/).

| Setting | Source | Purpose |
| --- | --- | --- |
| `process.executor = 'google-batch'` | fixed | Run each task as a Batch job |
| `process.machineType` | fixed | VM size (or set `cpus`/`memory` and let Batch derive it) |
| `google.project` | `env('GOOGLE_CLOUD_PROJECT')` (auto) | Workspace GCP project |
| `google.location` | `params.location` (default `us-central1`) | Region for Batch VMs; must match the workspace |
| `google.batch.serviceAccountEmail` | `env('GOOGLE_SERVICE_ACCOUNT_EMAIL')` (auto) | Workbench Pet SA |
| `workDir` | `params.work_dir` | GCS scratch (UI-managed on the UI path) |
| `network` / `subnetwork` + `usePrivateAddress` | fixed | Workbench VPC; private VMs, NAT egress |
| `process.container` | `params.container` | Task image (default `debian:stable-slim`) |

The two `env('...')` reads are the only environment dependencies, and both are
platform-injected on the CLI and the UI. `env(...)` is the strict-parser-safe way
to read an OS env var.

## See also

- Run an nf-core pipeline on Workbench:
  [`../nf-core-workbench-profile/`](../nf-core-workbench-profile/README.md).
- Convert a pipeline whose source code assumes local/HPC execution:
  [`nextflow-to-workbench` skill](../../claude/skills/nextflow-to-workbench/SKILL.md).
- Background talk: [Nextflow on Workbench slide outline](../nextflow-on-workbench-slides.md).
