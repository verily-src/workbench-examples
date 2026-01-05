#!/bin/bash

set -o errexit
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
ENV="local"
PUSH=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--env local|gcp|wb] [--push]"
            echo ""
            echo "Options:"
            echo "  --env   Environment to build for (local, gcp, or wb). Default: local"
            echo "  --push  Push the image to the registry after building (only for gcp/wb)"
            echo "  -h, --help  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                      # Build for local environment"
            echo "  $0 --env gcp --push     # Build for GCP and push to registry"
            echo "  $0 --env wb --push      # Build for Workbench and push to registry"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENV" =~ ^(local|gcp|wb)$ ]]; then
    echo "Error: Invalid environment '$ENV'. Must be 'local', 'gcp', or 'wb'"
    exit 1
fi

# Source environment configuration
CONFIG_FILE="${SCRIPT_DIR}/config/${ENV}.env"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Handle local environment (no push)
if [[ "$ENV" == "local" ]]; then
    if [[ "$PUSH" == "true" ]]; then
        echo "Warning: --push flag is not applicable for local environment, ignoring"
    fi

    echo "Building Docker image for local use: ${IMAGE_NAME}:${IMAGE_TAG}"
    docker build --platform linux/amd64 -f envs/containers/Dockerfile -t "${IMAGE_NAME}:${IMAGE_TAG}" .

    echo ""
    echo "Image built successfully!"
    echo "To run locally: scripts/run.sh --env local"
    exit 0
fi

# Handle GCP/Workbench environments
echo "Building Docker image: ${REGISTRY_PATH}"
docker build --platform linux/amd64 -f envs/containers/Dockerfile -t "${REGISTRY_PATH}" .

if [[ "${PUSH}" == "true" ]]; then
    echo ""
    echo "Configuring Docker authentication for Google Artifact Registry..."
    gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

    echo "Pushing image to registry..."
    docker push "${REGISTRY_PATH}"

    echo ""
    echo "Image successfully pushed to: ${REGISTRY_PATH}"
else
    echo ""
    echo "Image built successfully!"
    echo "To push to registry, run: $0 --env ${ENV} --push"
    echo "Or manually push with: docker push ${REGISTRY_PATH}"
fi
