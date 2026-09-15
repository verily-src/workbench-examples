# Reuse the public Workbench app startup scripts and MCP implementation.
FROM golang:1.25-bookworm AS workbench
ARG WORKBENCH_REF=5b8f501a381237098419f0d46e56cd023daa4119
ADD https://github.com/verily-src/workbench-app-devcontainers/archive/${WORKBENCH_REF}.tar.gz /tmp/workbench.tar.gz
RUN mkdir /src \
    && tar -xzf /tmp/workbench.tar.gz -C /src --strip-components=1 \
    && cd /src/features/src/wb-mcp-server \
    && CGO_ENABLED=0 go build -trimpath -o /wb-mcp-server .

# Same base as the official workbench-jupyter-with-llm template at WORKBENCH_REF.
FROM us-west2-docker.pkg.dev/shared-pub-buckets-94mvrf/workbench-artifacts/app-workbench-jupyter@sha256:6960bfaf61679dcd3098a588214d559c7d3b1edd4cc90efcc98a63af0b90a9b3
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl fuse git jq lsof openjdk-17-jre-headless procps sudo \
    && ln -s "/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)" /opt/nextflow-java \
    && rm -rf /var/lib/apt/lists/*

# The distribution includes the runtime JAR; no bootstrap download at first launch.
ADD https://github.com/nextflow-io/nextflow/releases/download/v26.04.6/nextflow-26.04.6-dist /usr/local/bin/nextflow
RUN echo '182a63c74074e2dc7956ffa3c8cd59de952ed2c44394e21faf5e1736b945444c  /usr/local/bin/nextflow' | sha256sum -c - \
    && chmod 755 /usr/local/bin/nextflow

COPY --from=workbench /wb-mcp-server /opt/wb-mcp-server/wb-mcp-server
COPY --from=workbench /src/startupscript /opt/workbench/startupscript
COPY --from=workbench /src/LICENSE /opt/workbench/LICENSE
COPY .devcontainer/mcp-config.json /opt/nextflow-app/mcp-config.json
COPY skills/ /opt/nextflow-app/skills/
# Docker initializes the home volume from the image only once, preserving edits
# and the local Nextflow cache on later container restarts/rebuilds.
COPY --chown=jupyter:jupyter . /home/jupyter/repos/hello-nf-on-wb/
RUN mkdir -p /home/jupyter/.agents/skills \
    && ln -s /opt/nextflow-app/skills/workbench-nextflow /home/jupyter/.agents/skills/workbench-nextflow \
    && chown -R jupyter:jupyter /home/jupyter/.agents
ENV JAVA_HOME=/opt/nextflow-java
ENV NXF_JAVA_HOME=/opt/nextflow-java
ENV PATH="/opt/wb-mcp-server:/opt/nextflow-java/bin:/usr/local/bin:${PATH}"
USER jupyter
WORKDIR /home/jupyter
RUN nextflow -version
