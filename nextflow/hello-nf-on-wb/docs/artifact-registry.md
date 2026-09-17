# Build and use a task image from Artifact Registry

This exercise uses Google Cloud Build to build a small container and push it to
a private Artifact Registry repository, then uses it for `convertToUpper` on
Workbench. The other processes keep their public images. You do not need Docker
installed locally for this path. Local Docker builds and tests are optional.
Run the commands from `nextflow/hello-nf-on-wb/`.

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

Use a Workbench app terminal, or a local terminal with `gcloud` and `wb`
installed and authenticated. Select your workspace:

```sh
wb workspace set --id='<your-workspace-id>'
wb workspace describe
```

Set `AR_PROJECT` to the workspace's Google Cloud project ID shown above and
choose a new or existing Docker repository name. Read the region directly from
the workspace:

```sh
export AR_PROJECT='<workspace-google-cloud-project-id>'
export AR_REGION="$(wb workspace describe | awk '$1 == "terra-default-location:" {print $2}')"
export AR_REPOSITORY='nextflow-tools'
export AR_HOST="${AR_REGION}-docker.pkg.dev"
export IMAGE_PATH="${AR_HOST}/${AR_PROJECT}/${AR_REPOSITORY}/hello-nf-tools"
export IMAGE_TAG="${IMAGE_PATH}:1.0.0"
```

If the repository does not already exist, create it once:

```sh
gcloud artifacts repositories create "$AR_REPOSITORY" \
  --project="$AR_PROJECT" \
  --repository-format=docker \
  --location="$AR_REGION" \
  --description='Task images for Nextflow examples'
```

The image URI and Cloud Build commands below use this same workspace region.

## 3. Check the build and runtime identities

Building an image and running a task use separate identities:

| Operation | Identity that needs access | Repository role |
| --- | --- | --- |
| Build and push with Cloud Build | The build's execution service account | `roles/artifactregistry.writer` |
| Push with local Docker (optional) | The user or service account authenticated to Docker | `roles/artifactregistry.writer` |
| Pull the image for a task | The Google Batch job service account | `roles/artifactregistry.reader` |

These roles can be granted on the individual repository. Existing workspace
permissions may already provide the required access. See Google's
[push/pull permissions](https://docs.cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling).

This example's `workbench` profile uses `GOOGLE_SERVICE_ACCOUNT_EMAIL` for the
Batch job service account. Inspect `wb auth status` and your job configuration
to identify the workspace Pet Service Account. A successful image build or push does not establish whether that account can
pull the image.

Cloud Build needs `cloudbuild.googleapis.com` enabled. The submitting identity
needs permission to create builds, upload the source, and, when required, act
as the selected build service account. The execution account also needs access to read staged source
and write build logs in the bucket used below. Artifact Registry Writer covers
image publication; it does not grant those build or storage permissions.

Check the actual build execution account in Cloud Build's settings or build
details; the default can differ by project. It may differ from both the
submitting identity and the Batch Pet Service Account. You can inspect the
project default before submitting:

```sh
wb gcloud builds get-default-service-account \
  --project="$AR_PROJECT" --region="$AR_REGION"
```

See Google's
[build submission permissions](https://docs.cloud.google.com/build/docs/securing-builds/configure-access-to-resources)
and [build service account guidance](https://docs.cloud.google.com/build/docs/securing-builds/configure-access-for-cloud-build-service-account).

If grants are missing, a repository administrator can run the following with
the actual build identity and Batch service account. `AR_WRITER_MEMBER` uses
`user:email` for a user or `serviceAccount:email` for a service account.

```sh
export AR_WRITER_MEMBER='serviceAccount:<cloud-build-execution-service-account-email>'
export BATCH_SERVICE_ACCOUNT='<workspace-pet-service-account-email>'

wb gcloud artifacts repositories add-iam-policy-binding "$AR_REPOSITORY" \
  --project="$AR_PROJECT" --location="$AR_REGION" \
  --member="$AR_WRITER_MEMBER" --role=roles/artifactregistry.writer

wb gcloud artifacts repositories add-iam-policy-binding "$AR_REPOSITORY" \
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

## 4. Build, check, and push

### Cloud Build (recommended for Workbench)

Use an existing Workbench bucket resource for build source and logs, as in the
[Workbench Cloud Build instructions](https://support.workbench.verily.com/docs/guides/cloud_apps/advanced_app_usage/create_container_images/#use-cloud-build-to-build-and-push-a-docker-image-to-the-artifact-registry).
This example uses `nf-scratch` from the [workspace setup](../README.md#one-time-workspace-setup).
Resolve it to a `gs://` URI before submitting:

```sh
export NF_BUILD_BUCKET="$(wb resource resolve --name=nf-scratch | xargs)"

wb gcloud builds submit containers/greetings \
  --project="$AR_PROJECT" --region="$AR_REGION" \
  --gcs-source-staging-dir="${NF_BUILD_BUCKET}/cloudbuild/source" \
  --gcs-log-dir="${NF_BUILD_BUCKET}/cloudbuild/logs" \
  --tag="$IMAGE_TAG"
```

This uploads only `containers/greetings/`, builds its Dockerfile on Cloud Build,
and pushes the tagged image. The standard Cloud Build workers produce a Linux
AMD64 image for this example's Batch machines, regardless of your laptop's CPU.
The Dockerfile checks Bash, `ps`, `cat`, `tr`, and an uppercase conversion during
the build. Wait for `SUCCESS`, then continue to **Record the image digest** below.
Use the Workbench run in section 5 to verify the complete pipeline.

The command needs no `cloudbuild.yaml`. If your native `gcloud` already uses the
intended workspace identity, the same `gcloud builds submit` command works
without the `wb` prefix. The remote build needs no local `docker login` or
`docker push`. If `wb gcloud` itself asks for Docker, its utility wrapper is
configured to use a container: with native `gcloud` installed, select
`wb config set utility-mode LOCAL_PROCESS`, or use native `gcloud` with the
intended workspace credentials. See [Workbench utility modes](https://support.workbench.verily.com/docs/guides/cli/cli_commands/#utility).
See Google's [Cloud Build Dockerfile quickstart](https://docs.cloud.google.com/build/docs/build-push-docker-image#build_an_image_using_a_dockerfile).

### Local Docker (optional alternative)

Use this path if you want to build and test on a machine with Docker installed:

```sh
docker version
docker buildx version
```

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

Check the native `gcloud` account used by Docker's credential helper:

```sh
gcloud auth list --filter=status:ACTIVE --format='value(account)'
gcloud config get-value auth/impersonate_service_account
```

On a laptop, authenticate `gcloud` with your authorized build identity if needed.
In a Workbench app, use its configured credentials. `wb` authentication and
native `gcloud` authentication can differ; selecting a workspace does not grant
your laptop's `gcloud` account access to its repository.

Configure Docker authentication for the registry host, then push the tested
image. Run these native commands in the same terminal/user context as Docker:

```sh
gcloud auth configure-docker "$AR_HOST"
docker push "$IMAGE_TAG"
```

The helper uses the active `gcloud` identity, including configured impersonation;
keep `gcloud` on your `PATH`. See
[Google's Docker authentication guide](https://docs.cloud.google.com/artifact-registry/docs/docker/authentication).

### Record the image digest

After either build path, record the pushed digest and use that immutable
reference for pipeline runs.
The [image describe command](https://docs.cloud.google.com/sdk/gcloud/reference/artifacts/docker/images/describe)
accepts the tag you just pushed:

```sh
export IMAGE_DIGEST="$(wb gcloud artifacts docker images describe "$IMAGE_TAG" \
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
for the **job service account**. If a Cloud Build push fails, check Writer access
for its **execution service account**; for a local push, also check Docker
credential-helper authentication. An `exec format error` generally points
to an image built for a different CPU architecture.

### Optional local pipeline test

If Docker is available, you can also test the pipeline locally with the pushed
image. This is optional when you have verified the Cloud Build and Workbench
path:

```sh
nextflow run main.nf -profile docker,artifact_registry \
  --upper_container "$IMAGE_PIN"
```

On an ARM64 laptop, set `DOCKER_DEFAULT_PLATFORM=linux/amd64` for this command if
your Docker installation requires it to run the AMD64 image.
