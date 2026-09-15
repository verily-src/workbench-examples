# Build and use a task image from Artifact Registry

This exercise builds a small container, pushes it to a private Google Artifact
Registry repository, and uses it for `convertToUpper`. The other processes keep
their public images. Run the commands from `nextflow/hello-nf-on-wb/`.

## 1. Decide whether to build an image

Use an existing public image when it already contains your tool and the required
version, your workspace can reach its registry, and your organization permits
using it. For bioinformatics tools, the
[BioContainers registry](https://biocontainers-edu.readthedocs.io/en/latest/what_is_biocontainers.html)
provides images such as `quay.io/biocontainers/<tool>:<version-and-build>`.
Choose a real tag from the tool's registry listing; this is a URI pattern.
This greeting pipeline only needs Bash and coreutils, already in `debian:12-slim`.

Build and upload an image when you have an internal tool, a patched dependency,
or a combination of tools that an existing image does not provide. A private
repository also lets you control access and retain an approved build. If a
public image already works but you want to keep a copy in your own registry,
pull, retag, and push it; rebuilding is unnecessary. Workbench recommends
Artifact Registry for nf-core workflows; see its
[Nextflow guide](https://support.workbench.verily.com/docs/guides/workflows/nextflow/#other-considerations).

The supplied [Dockerfile](../containers/greetings/Dockerfile) verifies Bash,
`cat`, and `tr`, sets the locale, and installs `procps` for resource metrics.
Nextflow's [container requirements](https://www.nextflow.io/docs/latest/container.html)
include Bash and `ps`. Add your own tool installation when adapting the example,
and let Nextflow supply the task command. The build context is just
`containers/greetings/`.

## 2. Select the workspace and repository

Use a Workbench app terminal with Docker and the Google Cloud CLI available, or
a local terminal with Docker, `gcloud`, and `wb` installed. Check Docker first:

```sh
docker version
docker buildx version
wb status
wb workspace set --id='<your-workspace-id>'
wb workspace describe
```

Copy the workspace's Google Cloud project ID from `wb workspace describe` or
the Workbench overview page. In a Workbench app it is also available as
`GOOGLE_CLOUD_PROJECT`. Set these shell variables using your own values:

```sh
export AR_PROJECT='<workspace-google-cloud-project-id>'
export AR_REGION='us-central1'  # use your workspace's region
export AR_REPOSITORY='nextflow-tools'
export AR_HOST="${AR_REGION}-docker.pkg.dev"
export IMAGE_PATH="${AR_HOST}/${AR_PROJECT}/${AR_REPOSITORY}/hello-nf-tools"
export IMAGE_TAG="${IMAGE_PATH}:1.0.0"
```

Use an existing Docker repository if your team has one. Otherwise, an authorized
workspace administrator can create it as in the
[Workbench container guide](https://support.workbench.verily.com/docs/guides/cloud_apps/advanced_app_usage/create_container_images/#create-an-artifact-registry-repository):

```sh
wb gcloud artifacts repositories list \
  --project="$AR_PROJECT" --location="$AR_REGION"

# Run once, only when the repository does not already exist.
wb gcloud artifacts repositories create "$AR_REPOSITORY" \
  --project="$AR_PROJECT" --location="$AR_REGION" \
  --repository-format=docker \
  --description='Task images for Nextflow examples'
```

Repository creation requires permissions beyond pushing images, for example
Artifact Registry Administrator. If the API is disabled, have the workspace
administrator enable `artifactregistry.googleapis.com`. See Google's
[Artifact Registry setup guide](https://docs.cloud.google.com/artifact-registry/docs/docker/store-docker-container-images).

## 3. Check the build and runtime identities

There are two operations with different permissions:

| Operation | Identity that needs access | Repository role |
| --- | --- | --- |
| Push this Docker build | The user or service account authenticated to Docker | `roles/artifactregistry.writer` |
| Pull the image for a task | The Google Batch job service account | `roles/artifactregistry.reader` |

These roles can be granted on the individual repository. Existing workspace
permissions may already provide the required access. See Google's
[push/pull permissions](https://docs.cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling).

This example's `workbench` profile uses `GOOGLE_SERVICE_ACCOUNT_EMAIL` for the
Batch job service account. Inspect `wb auth status` and your job configuration
to identify the workspace Pet Service Account. A successful push from your
laptop does not establish whether that account can pull the image.

Check the native `gcloud` account used by Docker's credential helper:

```sh
gcloud auth list --filter=status:ACTIVE --format='value(account)'
gcloud config get-value auth/impersonate_service_account
```

On a laptop, authenticate `gcloud` with your authorized build identity if needed.
In a Workbench app, use its configured credentials. `wb` authentication and
native `gcloud` authentication can differ; selecting a workspace does not grant
your laptop's `gcloud` account access to its repository.

If grants are missing, a repository administrator can run the following with
the actual build identity and Batch service account. `AR_WRITER_MEMBER` uses
`user:email` for a user or `serviceAccount:email` for a service account.

```sh
export AR_WRITER_MEMBER='serviceAccount:<build-service-account-email>'
export BATCH_SERVICE_ACCOUNT='<workspace-pet-service-account-email>'

gcloud artifacts repositories add-iam-policy-binding "$AR_REPOSITORY" \
  --project="$AR_PROJECT" --location="$AR_REGION" \
  --member="$AR_WRITER_MEMBER" --role=roles/artifactregistry.writer

gcloud artifacts repositories add-iam-policy-binding "$AR_REPOSITORY" \
  --project="$AR_PROJECT" --location="$AR_REGION" \
  --member="serviceAccount:${BATCH_SERVICE_ACCOUNT}" \
  --role=roles/artifactregistry.reader
```

For a registry in another project, apply the grant in the project that owns the
repository. Workbench also supports granting Reader to the proxy group reported
by `wb auth status` when access should extend to that group's workspace service
accounts. Follow the
[Workbench cross-project instructions](https://support.workbench.verily.com/docs/guides/cloud_apps/advanced_app_usage/create_container_images/#granting-access-to-a-private-artifact-registry-repo-in-a-separate-google-project)
and use `group:<proxy-group-email>` as the member.

If you use Cloud Build instead of local Docker, the build's execution service
account needs Writer; check the actual account in the build configuration. It
may differ from both your user and the Batch service account.

## 4. Build, check, and push

Build a Linux AMD64 image for this pipeline's `e2-small` Batch machines. Explicit
`--platform` matters on Apple Silicon, where a native build otherwise targets
ARM64. Docker Desktop supports emulation; other builders need AMD64 support.
See [Docker's platform guide](https://docs.docker.com/build/building/multi-platform/).

```sh
docker buildx build --platform linux/amd64 --load \
  --tag "$IMAGE_TAG" containers/greetings

docker run --rm --platform linux/amd64 "$IMAGE_TAG" \
  bash -c "printf 'Hello\nBonjour\nHola\n' | tr '[:lower:]' '[:upper:]'"
```

Expected output:

```text
HELLO
BONJOUR
HOLA
```

The Dockerfile uses a Debian major-version tag. That base can receive updates;
to fix the base for future rebuilds, record its digest and supply it through the
`BASE_IMAGE` build argument, for example
`--build-arg BASE_IMAGE='debian:12-slim@sha256:<base-digest>'`.
Docker explains [digest pinning](https://docs.docker.com/reference/cli/docker/image/pull/#pull-an-image-by-digest-immutable-identifier).
The installed `procps` package can also change between builds. Pin package
versions against a package repository snapshot if you need reproducible rebuilds;
the pushed image digest below fixes the complete image used for this run.

Configure Docker authentication for the registry host, then push the tested
image. Run these native commands in the same terminal/user context as Docker:

```sh
gcloud auth configure-docker "$AR_HOST"
docker push "$IMAGE_TAG"
```

The helper uses the active `gcloud` identity, including configured impersonation;
keep `gcloud` on your `PATH`. See
[Google's Docker authentication guide](https://docs.cloud.google.com/artifact-registry/docs/docker/authentication).

Record the pushed digest and use that immutable reference for pipeline runs.
The [image describe command](https://docs.cloud.google.com/sdk/gcloud/reference/artifacts/docker/images/describe)
accepts the tag you just pushed:

```sh
export IMAGE_DIGEST="$(gcloud artifacts docker images describe "$IMAGE_TAG" \
  --project="$AR_PROJECT" --format='value(image_summary.digest)')"
test -n "$IMAGE_DIGEST"
export IMAGE_PIN="${IMAGE_PATH}@${IMAGE_DIGEST}"
printf '%s\n' "$IMAGE_PIN"
```

Keep the tag as a human-readable release name. Push a new tag when the image
changes, then deliberately update the digest in the pipeline's run parameters.

## 5. Use the image for one process

The `artifact_registry` profile includes
[`conf/artifact-registry.config`](../conf/artifact-registry.config), which uses
a process selector:

```groovy
process {
    withName: convertToUpper {
        container = params.upper_container
    }
}
```

`withName` overrides the image declared in that process module. `sayHello` and
`collectGreetings` keep their own images, illustrating how each process can use
the tool it needs. See [Nextflow selector precedence](https://www.nextflow.io/docs/latest/config.html#selector-priority).

Test the complete pipeline locally with Docker and the pushed image:

```sh
nextflow run main.nf -profile docker,artifact_registry \
  --upper_container "$IMAGE_PIN"
```

On an ARM64 laptop, set `DOCKER_DEFAULT_PLATFORM=linux/amd64` for this command if
your Docker installation requires it to run the AMD64 image.

For a Workbench CLI run, follow the [workspace setup](../README.md#one-time-workspace-setup)
first, then resolve the scratch bucket and pass the image reference explicitly:

```sh
export NF_WORK_BUCKET="$(wb resource resolve --name=nf-scratch | xargs)"

wb nextflow run main.nf -profile workbench,artifact_registry \
  --upper_container "$IMAGE_PIN" \
  --outdir "${NF_WORK_BUCKET}/hello-nf-on-wb/results"
```

For the Workflows UI, select profiles `workbench,artifact_registry` and add the
literal image URI to your uploaded params file. Shell variables in YAML are not
expanded:

```yaml
outdir: 'gs://<your-bucket>/hello-nf-on-wb/results'
upper_container: '<region>-docker.pkg.dev/<project>/<repository>/hello-nf-tools@sha256:<digest>'
```

After the run, confirm `COLLECTED-greetings.txt` appears in `outdir`, and inspect
a `convertToUpper` Batch job to verify its container URI matches the digest.
Check `sayHello` or `collectGreetings` to see the separate public image.
If a task cannot pull the private image, check the image URI and Reader access
for the **job service account**. If a push fails, check Docker authentication and
Writer access for the **build identity**. An `exec format error` generally points
to an image built for a different CPU architecture.
