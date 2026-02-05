#!/bin/bash

# Source the variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default to GCP environment
ENV="${1:-gcp}"

# Validate environment
if [[ ! "$ENV" =~ ^(gcp|wb)$ ]]; then
    echo "Error: Invalid environment '$ENV'. Must be 'gcp' or 'wb'"
    echo "Usage: $0 [gcp|wb]"
    exit 1
fi

# Source environment configuration
CONFIG_FILE="${SCRIPT_DIR}/config/${ENV}.env"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Set data directory path relative to script location
DATA_DIR="${SCRIPT_DIR}/../data"

# Upload data to GCS bucket
gcloud storage cp -r "${DATA_DIR}" gs://${GCS_BUCKET}/
