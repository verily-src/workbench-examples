#!/bin/bash

set -o errexit
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
ENV="local"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--env local|gcp|wb]"
            echo ""
            echo "Options:"
            echo "  --env   Environment to run in (local, gcp, or wb). Default: local"
            echo "  -h, --help  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Run locally with Docker"
            echo "  $0 --env gcp      # Run on Google Batch with local orchestration"
            echo "  $0 --env wb       # Run on Google Batch with Workbench orchestration"
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

# Navigate to repository root
cd "${SCRIPT_DIR}/.."

# Handle local environment
if [[ "$ENV" == "local" ]]; then
    echo "Running Nextflow locally with Docker profile..."

    # Activate conda environment if available
    if command -v conda &> /dev/null; then
        eval "$(conda shell.bash hook)"
        if conda env list | grep -q "AMR++_env"; then
            conda activate AMR++_env
        else
            echo "Warning: AMR++_env conda environment not found"
            echo "Please create it with: conda env create -f envs/AMR++_env.yaml"
            exit 1
        fi
    else
        echo "Error: conda not found. Please install conda and create the AMR++_env environment"
        exit 1
    fi

    nextflow run main_AMR++.nf -profile "${NEXTFLOW_PROFILE}"
    exit 0
fi

# Handle GCP/Workbench environments
echo "Running Nextflow on Google Batch..."
echo "Profile: ${NEXTFLOW_PROFILE}"
echo "Config: ${NEXTFLOW_CONFIG}"
echo ""

# Handle conda environment for Workbench
if [[ "$ENV" == "wb" ]]; then
    if command -v conda &> /dev/null; then
        # Initialize conda if not already initialized
        if ! grep -q "conda initialize" ~/.bashrc 2>/dev/null; then
            echo "Initializing conda..."
            conda init bash
            source ~/.bashrc
        fi

        # Ensure conda is properly initialized for this shell
        eval "$(conda shell.bash hook)"

        # Check if AMR++_env exists, create if it doesn't
        if ! conda env list | grep -q "AMR++_env"; then
            echo "Creating AMR++_env conda environment with Nextflow v24..."
            echo "This may take a few minutes..."
            conda env create -f envs/AMR++_env.yaml
            echo "AMR++_env environment created successfully"
        else
            echo "AMR++_env conda environment found"
        fi

        # Activate the environment
        echo "Activating AMR++_env conda environment..."
        conda activate AMR++_env

        # Verify Nextflow version
        echo "Using Nextflow version: $(nextflow -version 2>&1 | grep -o 'version [0-9.]*' | head -1)"
    else
        echo "Error: conda not found. Please install conda first."
        exit 1
    fi
else
    # For GCP environment, just try to activate if available
    if command -v conda &> /dev/null; then
        eval "$(conda shell.bash hook)"
        if conda env list | grep -q "AMR++_env"; then
            conda activate AMR++_env
        else
            echo "Warning: AMR++_env conda environment not found, continuing without it"
        fi
    fi
fi

# Run nextflow with Google Batch profile
nextflow run main_AMR++.nf -profile "${NEXTFLOW_PROFILE}" -c "${NEXTFLOW_CONFIG}"
