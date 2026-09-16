# Nextflow on Verily Workbench

Use Nextflow to run a small greeting pipeline or two RNA-seq examples on Google
Batch. Start with the [directory README](https://github.com/verily-src/workbench-examples/blob/main/nextflow/README.md) to choose between managed
Workbench Workflows and direct execution from a cloud app.

## 1. Prepare a GCP workspace

Use an existing GCP-backed workspace or duplicate a demonstration workspace if
one has been shared with you. Duplication is optional. Check that you can use its
cloud apps and write to the buckets chosen for scratch and results.

For the RNA-seq notebook, identify two bucket resource IDs (they may refer to
the same bucket). Resource IDs are Workbench names, not physical GCS bucket names:

- **Scratch:** task working files needed for debugging and resume.
- **Results:** durable published files and MultiQC reports.

If you need buckets, [workspace_setup.ipynb](https://github.com/verily-src/workbench-examples/blob/main/workspace_setup.ipynb) creates
`ws_files` and `ws_files_autodelete_after_two_weeks`. The notebook defaults to
`ws_files` for both uses. Do not select the autodelete bucket for results you want
to keep. Its two-week retention also limits how long scratch files can be reused.
You can skip the setup notebook's BigQuery section for these examples.

Alternatively, create a bucket in the intended workspace using the CLI:

```sh
wb resource create gcs-bucket --workspace=<workspace-id> --id=nf-results
wb resource resolve --workspace=<workspace-id> --id=nf-results
```

Set the notebook's bucket variables to the resource IDs you actually use.

## 2. Open a JupyterLab cloud app

Create or start a JupyterLab cloud app from your workspace's cloud app controls.
For the notebook path, it needs Git, Python 3, the Workbench CLI and a local
Nextflow installation. Follow the [Nextflow installation guide](https://www.nextflow.io/docs/stable/install.html)
if Nextflow is absent; the notebook uses version 25.10.2. Configure and authenticate
the Workbench CLI as described in [basic usage](https://support.workbench.verily.com/docs/guides/cli/basic_usage/).

If this repository was not cloned automatically, use a terminal:

```sh
git clone https://github.com/verily-src/workbench-examples.git
```

Open `workbench-examples/nextflow/nextflow_examples.ipynb`. Public pipeline
repositories are fetched by the notebook over HTTPS; no GitHub SSH setup or
preconfigured repository resources are needed.

## 3. Choose an example

- **First Nextflow run:** follow [hello-nf-on-wb](https://github.com/verily-src/workbench-examples/blob/main/nextflow/hello-nf-on-wb/README.md). Its
  managed Workflows path does not require a running notebook app.
- **RNA-seq:** run the notebook's shared setup, then either or both examples.
  Example 1 uses a small chicken dataset with `rnaseq-nf`; Example 2 uses the
  yeast test profile of `nf-core/rnaseq` 3.22.2. Keep the cloud app running until
  the selected direct CLI run finishes.

Run All launches both RNA-seq examples once the settings are filled in. It does
not resume runs or delete scratch files. Compute and storage incur charges;
actual usage depends on the workspace and pipeline.

## 4. Inspect results

The notebook verifies and downloads each MultiQC report from the result bucket.
Open the downloaded HTML in a browser. A report's presence alone does not prove
that a new run succeeded: also check the current run's exit status and logs.
Notebook snapshots and report-preview folders are optional workspace resources;
these instructions do not depend on them.

For configuration, monitoring and troubleshooting, see the
[managed Workflows guide](https://support.workbench.verily.com/docs/guides/workflows/nextflow/)
and [Nextflow CLI guide](https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/).
