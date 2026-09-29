---
name: workbench-nextflow
description: Develop, run, and diagnose this Hello Nextflow example on Verily Workbench with Google Batch, including workspace context, cloud paths, and session locks.
---

# Nextflow on Workbench

In the Nextflow Workbench app, the example is in `/home/jupyter/repos/hello-nf-on-wb`.
Read its `README.md` and `nextflow.config` before composing a run. Read any
relevant available guide in its `docs/` directory for additional app guidance.
The teaching workflow follows the official
[Hello Nextflow training](https://github.com/nextflow-io/training/tree/master/hello-nextflow).

## Workspace and execution context

- Use the connected `wb` MCP server's advertised tools for workspace/resource
  discovery. If the server lacks a needed Nextflow operation, use the repository's
  documented `wb nextflow` CLI path; do not invent MCP tool names or flags.
- `wb auth status`, `wb workspace describe`, and `wb resource list` establish the
  CLI context. In a GCP app, `wb auth login --mode=APP_DEFAULT_CREDENTIALS` uses
  the app identity. Run the agent as the terminal user (`jupyter`), so it shares the
  same Workbench authentication and workspace context.
- Resolve a bucket resource with `wb resource resolve --name=<resource-name>`.
  Use its returned `gs://` URI at run time. Keep physical bucket names, workspace
  IDs, project IDs, and credentials out of committed example configuration.
- The `standard` profile runs locally in the app. The `workbench` profile runs
  process containers on Google Batch; `wb nextflow` supplies the workspace
  project and service account variables. Check the selected region and nonempty
  `NF_WORK_BUCKET`, then supply a `gs://` output directory as described in the
  README. The browser app is the Nextflow head process environment, not the
  Batch task container.
- Submitting a run creates cloud jobs. Use the user's selected workspace, data,
  and scope. A request for diagnostics alone does not authorize a new run or
  deletion of jobs, data, or caches.

## Sessions, work directories, and failures

Keep the launch directory and `.nextflow/` cache on the app's local `/home/jupyter`
volume. Use GCS for the Batch work directory and final outputs. A FUSE-mounted
bucket is unsuitable for the local Nextflow LevelDB session cache.

For `Unable to acquire lock on session`, identify the session and inspect the
exact lock path, for example:

```sh
lsof '.nextflow/cache/<session-id>/db/LOCK'
```

Check the reported process and the run log. An empty `lsof` result alone is not
proof that deletion is safe; it can reflect permissions or another process
namespace. Stop any active orchestrator using the cache before attempting
recovery. Do not delete `.nextflow`, the lock, or the cloud work directory as a
first response. Preserve the cache and task outputs needed for `-resume`.

An app restart can kill the orchestrator while Batch jobs remain in flight.
Before resubmitting, inspect the recorded Batch jobs and resolve their state to
avoid overlapping work. Nextflow `-resume` reuses eligible completed work; this
app does not provide automatic reattachment to in-flight jobs. Detached or
managed orchestration and reattachment are tracked separately in BENCH-9854.
