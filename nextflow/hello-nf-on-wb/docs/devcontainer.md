# Nextflow development app on Workbench

This [devcontainer](../.devcontainer/devcontainer.json) runs the Nextflow head
process in a browser JupyterLab app. Google Batch runs the workflow's process
containers. It includes Java 17, Nextflow 26.04.6, `lsof`, Google Cloud CLI,
the Workbench MCP server (`wb-mcp-server`), and a Nextflow-specific agent skill.
Workbench startup installs and configures `wb` for the app's environment.

The app follows the public
[Workbench Jupyter with LLM template](https://github.com/verily-src/workbench-app-devcontainers/tree/5b8f501a381237098419f0d46e56cd023daa4119/src/workbench-jupyter-with-llm):
the `application-server` container, external `app-network`, browser port 8888,
FUSE settings, and upstream Workbench startup/remount hooks. The Dockerfile pins
the upstream source commit and Jupyter image, and verifies the Nextflow
distribution's release checksum. It builds the
[official MCP implementation](https://github.com/verily-src/workbench-app-devcontainers/tree/5b8f501a381237098419f0d46e56cd023daa4119/features/src/wb-mcp-server)
without requiring an AI client or extension.

## Create the app

After the changes are available in a Git branch, follow Workbench's
[custom app guide](https://support.workbench.verily.com/docs/guides/cloud_apps/cloud_app_types/custom/)
with these settings:

| Setting | Value |
| --- | --- |
| Repository | This repository's Git URL |
| Ref | The branch or commit containing these files |
| Devcontainer path | `nextflow/hello-nf-on-wb` |
| Cloud | GCP |
| Browser port | `8888` |
| Login to Workbench CLI | Enable to use the app's default credentials |

Choose a VM with enough memory for the head process and its development tools.
Batch task resources are selected separately by the workflow configuration.
Keep the app running while a workflow is active; choose an appropriate idle
shutdown policy for the run.

On first creation, Docker seeds an editable copy of the example at
`/home/jupyter/repos/hello-nf-on-wb`. It keeps `/home/jupyter`, including the launch
directory, Nextflow cache, and editor settings, in a named Docker volume across container
restarts/rebuilds. Rebuilding preserves this copy; bring in later repository
changes explicitly. This volume belongs to the app VM: deleting/replacing the
VM is not a backup strategy. Keep inputs, Batch work files, and final outputs in
GCS, and preserve the local cache if you need to recover a session.

## Bring an agent

Install your preferred agent in the app and run it as `jupyter`, the browser
terminal user. The MCP server uses the same `wb` authentication and context.
Use the command-based MCP entry in
[`mcp-config.json`](../.devcontainer/mcp-config.json), also installed at
`/opt/nextflow-app/mcp-config.json`, in your client's MCP settings. Its command is:

```text
/opt/wb-mcp-server/wb-mcp-server
```

This uses the server's standard input/output transport, so the client starts
it on demand. No additional public app port is needed. Configure the command
inside the app, where `wb` and its credentials are available.

The [Nextflow skill](../skills/workbench-nextflow/SKILL.md) is preloaded at
`/opt/nextflow-app/skills/workbench-nextflow/SKILL.md` and linked under
`/home/jupyter/.agents/skills/`. Enable that skill directory in your client, or ask
it to read the file as context if it does not support skill discovery. Skills are
instruction files for the agent; the upstream MCP server exposes Workbench
tools and does not load skill files itself.

## Validate in Workbench

In the app terminal:

```sh
whoami                              # jupyter
java -version
nextflow -version                   # 26.04.6
lsof -v
wb auth status
wb workspace describe
wb resource list
cd /home/jupyter/repos/hello-nf-on-wb
nextflow run main.nf -profile standard
cat results/COLLECTED-greetings.txt
```

If automatic login was disabled, run
`wb auth login --mode=APP_DEFAULT_CREDENTIALS` and select your workspace before
using cloud tools. In the agent, connect the `wb` server and list its tools,
then use a read-only workspace/resource discovery tool to verify the connection.
Follow the [CLI run instructions](../README.md) for a small Google Batch run,
using a resolved workspace bucket and unique output prefix.

After the run finishes, restart the app and verify that the editable project,
`.nextflow/` cache, authentication, and mounted workspace resources are still
available. The local cache should be under `/home/jupyter/repos/hello-nf-on-wb`, not
inside a bucket mount.

The Docker daemon and Workbench VM are needed to finish build/startup testing.
This template's Workbench provisioning, credential integration, and restart
behavior must be verified on a Workbench app before calling the app validated.

## Orchestrator lifecycle

Hosting the head process in this app provides a consistent environment. It does
not make the orchestrator resilient to a VM stop, process crash, or network
failure; the incident motivating this work also occurred inside a Workbench
app VM. This template does not supervise/restart Nextflow or reattach it to
in-flight Batch jobs. `-resume` can reuse eligible completed work if its cache
and outputs survive. Detached/managed orchestration and reattachment remain
the separate feature request
[BENCH-9854](https://verily.atlassian.net/browse/BENCH-9854).
