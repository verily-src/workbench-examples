# A small task image for the greeting pipeline. Debian 12 includes Bash and
# GNU coreutils; procps adds ps for Nextflow task metrics. All tools are installed
# at build time, so no package installation is needed when a task starts.
# Override BASE_IMAGE with debian:12-slim@sha256:<digest> to pin the base exactly.
ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="hello-nf-tools" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Bash, GNU coreutils and procps for the Hello Nextflow training example"

ENV LC_ALL=C

# Install the metrics dependency and verify the task commands at build time.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/* \
    && bash --version > /dev/null \
    && ps --version > /dev/null \
    && cat --version > /dev/null \
    && tr --version > /dev/null \
    && test "$(printf 'Hello\n' | tr '[:lower:]' '[:upper:]')" = 'HELLO'

# Nextflow supplies its own Bash command. Do not set a tool-specific ENTRYPOINT.
CMD ["/bin/bash"]
