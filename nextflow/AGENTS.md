# Nextflow examples

This directory teaches Nextflow on GCP-backed Verily Workbench workspaces.

- `README.md` is the repository entry point; `workspace_description.md` is the
  workspace-facing introduction. Keep prerequisites and example names aligned.
- `nextflow_examples.ipynb` teaches direct `wb nextflow` execution with two
  RNA-seq pipelines. `hello-nf-on-wb/` is the small introductory pipeline.
- Managed Workflows (UI or `wb workflow`) supply Batch infrastructure settings.
  Direct `wb nextflow` supplies workspace context to a locally launched engine;
  it still needs an executor configuration. Do not conflate their profiles,
  monitoring, local cache, or resume instructions.
- Use Google Batch. Resolve bucket resource IDs to GCS URLs; do not commit
  workspace-specific project IDs, accounts, bucket names, or executed outputs.
- Keep pipeline revisions and test data explicit. Check their Nextflow version
  requirements, container settings and output paths before updating a pin.
- Notebook commands must fail on nonzero exit status. Keep destructive cleanup
  as manual instructions, never executable as part of Run All. Do not overwrite
  a user's home-directory config or modify an upstream pipeline checkout.
- Validate notebook JSON/schema, Python cell syntax, links and command behavior.
  Check effective Nextflow configuration and the hello output when the runtime
  is available. Clearly distinguish static checks, mocked checks, local runs and
  cloud runs. A submitted Batch job is not proof of successful output.

Authoritative references:

- https://support.workbench.verily.com/docs/guides/workflows/nextflow/
- https://support.workbench.verily.com/docs/guides/cli/cli_nextflow/
- https://www.nextflow.io/docs/stable/google.html
- When available, Workbench CLI and workflow-manager source in the local
  `../verily1/workbench` checkout. Record its revision; source presence does not
  establish deployment availability.
