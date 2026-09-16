# Nextflow on Verily Workbench

Start with [hello-nf-on-wb](hello-nf-on-wb/README.md), a small pipeline that reads
greetings, uppercases them in parallel, and publishes one result. It includes
local execution, managed Workflows, and direct CLI instructions.

For RNA sequencing examples, open [nextflow_examples.ipynb](nextflow_examples.ipynb)
in a Workbench JupyterLab cloud app. The notebook runs two independent examples
after shared setup:

1. `nextflow-io/rnaseq-nf`: a small chicken (*Gallus gallus*) RNA-seq dataset.
2. `nf-core/rnaseq`: the release's small yeast test dataset, with pinned read URLs.

Both use Google Batch and publish results, including MultiQC reports, to a
workspace bucket. The notebook records pipeline revisions, stops on command
failure, and explains logs, resume and manual cleanup. It does not require the
separate `nf-core` Python tool.

## Choose how to run

| Method | Who launches Nextflow? | Configuration and monitoring |
| --- | --- | --- |
| Workflows UI or `wb workflow` | Workbench runs the engine on managed infrastructure. | Workbench supplies project, region, service account, network and scratch settings. Supply pipeline parameters and a durable output path; monitor the Workbench job. |
| `wb nextflow` (this notebook) | The engine runs in your cloud app; tasks run on Google Batch. | Supply a Batch config. Keep the app running for orchestration and retain its local cache to resume. Inspect Nextflow logs and Batch jobs. |

See the [managed workflow guide](https://support.workbench.verily.com/docs/guides/workflows/nextflow/)
and [direct CLI guide](https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/).
Direct CLI runs are not registered Workbench workflow jobs.

## Before opening the notebook

- Use a GCP-backed workspace, an authenticated `wb` CLI, and a JupyterLab cloud
  app with Git, Python 3 and Nextflow available locally.
- The notebook targets Nextflow **25.10.2** with its default Groovy parser. It
  checks the engine version before running either pipeline. Its pins are
  `rnaseq-nf` commit `bad0c709877f5091b27db3a7f38118424e242e3c` and
  `nf-core/rnaseq` **3.22.2**; these are deliberate tutorial versions, not a
  claim to track the latest releases.
- Provide your workspace ID and writable bucket resource IDs in the first
  settings cell. An existing workspace works; duplication is optional.
- Keep final results in a bucket without an automatic deletion policy. Scratch
  can use a separate bucket, but expiration of scratch files prevents resume.
- Batch compute and storage incur charges. No fixed cost or duration is promised.

See [workspace setup instructions](workspace_description.md) for details. Cloud
execution of this refresh still needs validation in the target workspace; source
and notebook checks alone do not establish container access or successful jobs.
