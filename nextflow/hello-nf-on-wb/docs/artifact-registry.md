# Use an Artifact Registry container in hello-nextflow

Build and upload the supplied [Dockerfile](../containers/greetings/Dockerfile)
with Cloud Build, then use that image for `convertToUpper` in the workflow.
No local Docker installation is needed.

Run these commands in the same Workbench app terminal, from
`nextflow/hello-nf-on-wb/`, with your workspace selected and the
[`nf-data` bucket](../README.md#one-time-workspace-setup) created.

## 1. Create a repository

Read the project and region from the current workspace:

```sh
PROJECT="$(wb workspace describe | awk '$1 == "Google" && $2 == "project:" {print $3}')"
REGION="$(wb workspace describe | awk '$1 == "terra-default-location:" {print $2}')"
```

Create a Docker repository named `nextflow-tools` (skip this if it already exists):

```sh
gcloud artifacts repositories create nextflow-tools \
  --project="$PROJECT" \
  --repository-format=docker \
  --location="$REGION" \
  --description='Task images for Nextflow examples'
```

## 2. Build and upload the container

Reuse the workspace values for the image address and the scratch bucket for
build source and logs:

```sh
BUCKET="$(wb resource resolve --name=nf-data | xargs)"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/nextflow-tools/hello-nf-tools:1.0.0"

gcloud builds submit containers/greetings \
  --project="$PROJECT" --region="$REGION" \
  --gcs-source-staging-dir="${BUCKET}/cloudbuild/source" \
  --gcs-log-dir="${BUCKET}/cloudbuild/logs" \
  --tag="$IMAGE"
```

Wait for `SUCCESS`. Cloud Build builds the Dockerfile and pushes the image to
Artifact Registry.

## 3. Run hello-nextflow with the image

The [`artifact_registry` profile](../conf/artifact-registry.config) sets
`convertToUpper`'s container to `upper_container`. The other two processes keep
their existing images.

```sh
NF_WORK_BUCKET="$BUCKET" NF_REGION="$REGION" \
  wb nextflow run main.nf -profile workbench,artifact_registry \
  --upper_container "$IMAGE" \
  --outdir "${BUCKET}/hello-nf-on-wb/results"
```

After the workflow completes, read the result:

```sh
gcloud storage cat "${BUCKET}/hello-nf-on-wb/results/COLLECTED-greetings.txt"
```

Expect `HELLO`, `BONJOUR`, and `HOLA`, one per line, in any order. In the Batch
console, a `convertToUpper` job's container image should match `$IMAGE`.

For permissions and other registry setups, see the
[Workbench container image guide](https://support.workbench.verily.com/docs/guides/cloud_apps/advanced_app_usage/create_container_images/).
