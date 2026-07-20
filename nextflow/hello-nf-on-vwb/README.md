# hello-nf-on-vwb

A minimal [Nextflow](https://www.nextflow.io) pipeline, in the style of the
official [Hello Nextflow training](https://training.nextflow.io/hello_nextflow/),
that runs unchanged on your laptop or on Verily Workbench via
[Google Batch](https://www.nextflow.io/docs/latest/google.html#cloud-batch). It
reads greetings from a CSV, uppercases them in parallel, and collects them into
one file — the point is the Workbench wiring (profiles, params, containers, a GCS
work directory), not the string processing.

## Run locally

```sh
nextflow run main.nf -profile standard    # no container
nextflow run main.nf -profile docker      # in a container (Docker must be running)
```

Results land in `results/COLLECTED-greetings.txt`. Override inputs with `--input`
/ `--outdir`, or `-params-file test-params.yaml`.

## Run on Workbench (Google Batch)

Same pipeline code — you just point the paths at a bucket. `outdir` and `work_dir`
must be full `gs://` paths (the pipeline fails fast otherwise); `input` can stay
the bundled sample or point at your own data in a bucket. Your bucket's `gs://`
path is shown in the Workbench UI.

### One-time setup

Create a GCS bucket in your workspace — the UI's **Resources** tab, or:

```sh
wb resource create gcs-bucket --id=<your-bucket-id>
```

Workbench provides the rest (VPC, Cloud NAT, APIs, Pet Service Account).

### From the Workflows UI

Register the pipeline from its Git repo (main script
`nextflow/hello-nf-on-vwb/main.nf`, profile `verily_workbench`). The UI sets
`work_dir` for you; you supply `outdir` in a params file. The file must live in a
bucket (the UI's picker doesn't read the repo):

```yaml
# params.verily_workbench.yaml
outdir: "gs://<your-bucket>/hello-nf-on-vwb/results"
```

Upload it (via the UI, or `gcloud storage cp params.verily_workbench.yaml
gs://<your-bucket>/params/`), then select it in the job's **Set up parameters**
step. To use your own data, upload it and add an `input: "gs://…"` line.

### From the CLI (`wb nextflow`)

From a workspace app terminal (the workspace context is already set), `wb
nextflow` injects the project and service account for you:

```sh
wb nextflow run main.nf -profile verily_workbench \
  --work_dir gs://<your-bucket>/scratch \
  --outdir   gs://<your-bucket>/hello-nf-on-vwb/results
```

Add `--input gs://<your-bucket>/inputs/greetings.csv` (after staging your data
there) to use your own input.

### Where results go

Published results are at `outdir` (e.g.
`gs://<your-bucket>/hello-nf-on-vwb/results/COLLECTED-greetings.txt`) — not the
work dir, which is per-task scratch, safe to delete after a successful run. Logs
are in the job's **Logs** tab or Cloud Logging.

## Using a private container

The example uses the public `debian:stable-slim` image. For real tools, push an
image to [Artifact Registry](https://cloud.google.com/artifact-registry) and pass
`--container "<region>-docker.pkg.dev/<project>/<repo>/<image>:<tag>"`.
