# hello-nf-on-wb

A small [Nextflow](https://www.nextflow.io) pipeline in the style of the
[Hello Nextflow training](https://training.nextflow.io/hello_nextflow/).
It reads greetings from a CSV, writes each to a file, uppercases them in parallel,
and collects the results into `COLLECTED-greetings.txt`.

Use Nextflow **25.04 or later**; the tutorial notebook targets **25.10.2**.
`main.nf` and `modules/` describe the computation; `nextflow.config` selects how
it runs. The bundled input is located with `projectDir`, so launching from a
different directory does not break its path.

| Profile | Where to use it | Infrastructure settings |
| --- | --- | --- |
| `standard` | Local Nextflow | Local shell tools |
| `docker` | Local Nextflow with Docker | Local Docker |
| `workbench_managed` | Workflows UI or `wb workflow` | Supplied by Workbench; this profile only sets container and task resources |
| `workbench` | Direct `wb nextflow` | Supplied by this config using the CLI's workspace context and `NF_WORK_BUCKET` |

Choose one profile. The managed profile does not depend on app-terminal
variables, and the direct CLI profile fails if its required context is absent.

## 1. Run locally

From this directory:

```sh
nextflow run main.nf -profile standard
# Optional: use the local sample parameter file.
nextflow run main.nf -profile standard -params-file test-params.yaml
# Or, with Docker running:
nextflow run main.nf -profile docker
```

The result is `results/COLLECTED-greetings.txt`. It contains `HELLO`, `BONJOUR`,
and `HOLA`, one per line. Task completion order can vary, so compare the lines
without assuming an order.

## 2. Run through managed Workbench Workflows

Use a GCP-backed workspace and a writable bucket without an automatic deletion
policy for results. Set the intended workspace before creating or resolving
resources; reuse an existing bucket when possible:

```sh
wb workspace set --id=<your-workspace-id>
# Only if you need a new bucket:
wb resource create gcs-bucket --id=nf-results
```

In the Workflows UI, register this repository and select
`nextflow/hello-nf-on-wb/main.nf`. Link your GitHub account if prompted. When
creating a job, select profile **`workbench_managed`**. Workbench configures
Google Batch, including project, region, service account, network and scratch.
See the [managed workflow guide](https://support.workbench.verily.com/docs/guides/workflows/nextflow/).

The params-file picker reads from workspace bucket resources. Resolve the
resource ID to its physical GCS URL, create a file containing `outdir`, and upload
it from an app terminal (or use the resource upload UI):

```sh
BUCKET="$(wb resource resolve --id=nf-results --format=TEXT)"
printf 'outdir: "%s/hello-nf-on-wb/results"\n' "$BUCKET" > params.workbench.yaml
wb gcloud storage cp params.workbench.yaml "$BUCKET/params/params.workbench.yaml"
```

Choose `params/params.workbench.yaml` in the job's parameter setup. The default
input is bundled in the repository, so no CSV upload is needed for this run.
For your own data, upload the CSV and include an `input: gs://...` value in the
params file. Parameter files are read literally; shell variables are not expanded.
The local `test-params.yaml` uses local paths and is not a cloud params file.

Choose the job's output bucket/path as well. That location holds managed run
artifacts; **the pipeline's `outdir` controls its published result file**.
Monitor the Workbench job until it succeeds, then inspect
`<outdir>/COLLECTED-greetings.txt` and compare the three expected lines.

The CLI `wb workflow create` path uses a workflow already staged in a workspace
bucket. Upload the whole pipeline directory, including `modules/`, `data/`, and
`nextflow.config`; uploading `main.nf` alone is insufficient. Follow the managed
workflow guide for registration and job commands.

## 3. Run directly with `wb nextflow`

Use a cloud app with local Nextflow available and select the intended GCP
workspace. The app hosts the Nextflow engine and must remain running; Batch
executes the tasks. These runs are not registered Workbench workflow jobs.

```sh
export NF_WORK_BUCKET="$(wb resource resolve --id=nf-results --format=TEXT)"

# Inspect before submitting; this checks configuration, not cloud permissions.
wb nextflow config main.nf -profile workbench

wb nextflow run main.nf -profile workbench \
  --outdir "${NF_WORK_BUCKET}/hello-nf-on-wb/results"
```

`wb` injects `GOOGLE_CLOUD_PROJECT`, `GOOGLE_SERVICE_ACCOUNT_EMAIL` and
`PROJECT_DEFAULT_REGION` into the Nextflow process. The region has no hardcoded
fallback. If your CLI does not supply it, explicitly set `NF_REGION` to the
workspace region. The Batch subnetwork must be in that same region.

For your own input:

```sh
wb gcloud storage cp data/greetings.csv "${NF_WORK_BUCKET}/inputs/greetings.csv"
wb nextflow run main.nf -profile workbench \
  --input "${NF_WORK_BUCKET}/inputs/greetings.csv" \
  --outdir "${NF_WORK_BUCKET}/hello-nf-on-wb/results"
```

If bucket resolution fails, verify the resource ID and workspace, run
`wb resource list` to refresh the cache, and resolve it again. Do not proceed
with an empty bucket URL.

## Results, logs and resume

- **Published result:** `<outdir>/COLLECTED-greetings.txt`, in durable storage.
- **Scratch:** task working files. Managed runs receive a Workbench-selected
  work directory; direct runs use `${NF_WORK_BUCKET}/hello-nf-on-wb/scratch`.
- **Managed monitoring:** the Workbench job/task views and Google Batch logs.
- **Direct monitoring:** `.nextflow.log`, `wb nextflow log` in the launch
  directory, and the Google Batch console in the workspace project and region.

Direct CLI resume uses `-resume` and requires both the local `.nextflow` cache
and cloud scratch files. Keep both until you no longer need to resume. Local
history/cleanup commands do not manage Workbench-managed runs. A submitted job
or a previous result file does not establish success of the current run.

## Containers

This small example uses the public `debian:stable-slim` image. That tag is mutable.
For reproducible production use, pin an approved image digest. A direct CLI run
can override the image with `NF_CONTAINER`; for a managed run, set the container
in the committed `workbench_managed` profile. App-terminal variables do not
configure a remotely managed engine.

If public registry pulls fail, check Batch events and network access. The
[Workbench guide](https://support.workbench.verily.com/docs/guides/workflows/nextflow/)
describes Artifact Registry use. Building a private image is optional for this
small example.

## Next steps

Continue with the [RNA-seq notebook](../nextflow_examples.ipynb) or the
[direct CLI guide](https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/).
The profile separation has been checked against Workbench source; a cloud smoke
run is still required in the intended workspace to validate scheduling and output.
