#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default to GCP environment for infrastructure setup
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

if [[ -f ".env" ]]; then
    echo "Loading configuration from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    1>&2 echo "ERROR: Not authenticated with gcloud"
    1>&2 echo "Please run: gcloud auth login"
    exit 1
fi

if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]]; then
    1>&2 echo "ERROR: No default project set in gcloud config"
    1>&2 echo "Please run: gcloud config set project GOOGLE_CLOUD_PROJECT"
    exit 1
fi

echo "Using project: ${GOOGLE_CLOUD_PROJECT}"

echo "Configuration:"
echo "  Bucket: gs://${GCS_BUCKET}"
echo "  Service Account: ${GOOGLE_SERVICE_ACCOUNT_EMAIL}"
echo "  Artifact Repository: ${GOOGLE_ARTIFACT_REPO}"
echo ""

if [[ "$ENV" == "wb" ]]; then
    echo "Skipping API enablement (managed by Workbench)"
else
    echo "Enabling required APIs..."
    gcloud services enable iamcredentials.googleapis.com --project="${GOOGLE_CLOUD_PROJECT}" --quiet
    gcloud services enable artifactregistry.googleapis.com --project="${GOOGLE_CLOUD_PROJECT}" --quiet
    gcloud services enable batch.googleapis.com --project="${GOOGLE_CLOUD_PROJECT}" --quiet
    gcloud services enable compute.googleapis.com --project="${GOOGLE_CLOUD_PROJECT}" --quiet
fi

if [[ "$ENV" == "wb" ]]; then
    echo "Skipping VPC and NAT setup (managed by Workbench)"
else
    echo "Creating VPC network if it doesn't exist..."
    if gcloud compute networks describe default --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
        echo "Default VPC network already exists"
    else
        echo "Creating default VPC network..."
        gcloud compute networks create default \
            --subnet-mode=auto \
            --project="${GOOGLE_CLOUD_PROJECT}"

        echo "Creating firewall rules for default network..."
        gcloud compute firewall-rules create default-allow-internal \
            --network=default \
            --allow=tcp:0-65535,udp:0-65535,icmp \
            --source-ranges=10.128.0.0/9 \
            --project="${GOOGLE_CLOUD_PROJECT}"

        gcloud compute firewall-rules create default-allow-ssh \
            --network=default \
            --allow=tcp:22 \
            --source-ranges=0.0.0.0/0 \
            --project="${GOOGLE_CLOUD_PROJECT}"
    fi

    echo "Creating Cloud Router and NAT for private IP access..."
    if gcloud compute routers describe nat-router --region="${GCS_BUCKET_LOCATION}" --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
        echo "Cloud Router already exists"
    else
        echo "Creating Cloud Router..."
        gcloud compute routers create nat-router \
            --network=default \
            --region="${GCS_BUCKET_LOCATION}" \
            --project="${GOOGLE_CLOUD_PROJECT}"
    fi

    if gcloud compute routers nats describe nat-config --router=nat-router --region="${GCS_BUCKET_LOCATION}" --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
        echo "Cloud NAT already exists"
    else
        echo "Creating Cloud NAT..."
        gcloud compute routers nats create nat-config \
            --router=nat-router \
            --region="${GCS_BUCKET_LOCATION}" \
            --nat-all-subnet-ip-ranges \
            --auto-allocate-nat-external-ips \
            --project="${GOOGLE_CLOUD_PROJECT}"
    fi
fi

if [[ "$ENV" == "wb" ]]; then
    # For Workbench, use wb resource create
    if wb resource describe --id="${GCS_BUCKET}" &>/dev/null; then
        echo "Workbench GCS bucket resource already exists: ${GCS_BUCKET}"
    else
        echo "Creating GCS bucket via Workbench: ${GCS_BUCKET}"
        wb resource create gcs-bucket --id="${GCS_BUCKET}"
    fi
else
    # For GCP, use gcloud storage
    if gcloud storage buckets describe "gs://${GCS_BUCKET}" --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
        echo "Bucket already exists: gs://${GCS_BUCKET}"
    else
        echo "Creating GCS bucket: gs://${GCS_BUCKET}"
        gcloud storage buckets create "gs://${GCS_BUCKET}" \
            --project="${GOOGLE_CLOUD_PROJECT}" \
            --location="${GCS_BUCKET_LOCATION}" \
            --uniform-bucket-level-access \
            --lifecycle-file="lifecycle.json"
    fi
fi

# For Workbench environment, skip service account creation and IAM bindings
# The Pet SA is managed by Workbench and already has necessary permissions
if [[ "$ENV" == "wb" ]]; then
    echo "Using Workbench Pet Service Account: ${GOOGLE_SERVICE_ACCOUNT_EMAIL}"
    echo "Skipping IAM policy bindings (managed by Workbench)"
else
    # For GCP environment, create service account and grant permissions
    if gcloud iam service-accounts describe "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
        echo "Service account already exists: ${GOOGLE_SERVICE_ACCOUNT_EMAIL}"
    else
        echo "Creating service account: ${GOOGLE_SERVICE_ACCOUNT_EMAIL}"
        gcloud iam service-accounts create "$GOOGLE_SERVICE_ACCOUNT_NAME" \
            --display-name="GCS Uploader and Signer" \
            --project="${GOOGLE_CLOUD_PROJECT}"
    fi

    echo "Granting storage.objectAdmin role to service account..."
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/storage.objectAdmin" \
        --condition=None \
        --quiet

    echo "Granting iam.serviceAccountTokenCreator role to service account..."
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/iam.serviceAccountTokenCreator" \
        --condition=None \
        --quiet

    echo "Granting batch.agentReporter role to service account..."
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/batch.agentReporter" \
        --condition=None \
        --quiet

    echo "Granting logging.logWriter role to service account..."
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/logging.logWriter" \
        --condition=None \
        --quiet

    echo "Granting artifactregistry.reader role to service account..."
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --role="roles/artifactregistry.reader" \
        --condition=None \
        --quiet

    USER_EMAIL="$(gcloud config get-value account 2>/dev/null)"
    readonly USER_EMAIL

    if [[ -z "${USER_EMAIL}" ]]; then
        1>&2 echo "ERROR: Could not determine current user email"
        exit 1
    fi

    echo "Granting ${USER_EMAIL} permission to impersonate service account..."
    gcloud iam service-accounts add-iam-policy-binding "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
        --member="user:${USER_EMAIL}" \
        --role="roles/iam.serviceAccountTokenCreator" \
        --project="${GOOGLE_CLOUD_PROJECT}" \
        --quiet
fi

ARTIFACT_LOCATION="${GCS_BUCKET_LOCATION:-us-central1}"

if gcloud artifacts repositories describe "${GOOGLE_ARTIFACT_REPO}" --location="${ARTIFACT_LOCATION}" --project="${GOOGLE_CLOUD_PROJECT}" &>/dev/null; then
    echo "Artifact repository already exists: ${GOOGLE_ARTIFACT_REPO}"
else
    echo "Creating artifact repository: ${GOOGLE_ARTIFACT_REPO}"
    echo "Project: ${GOOGLE_CLOUD_PROJECT}"
    echo "Location: ${ARTIFACT_LOCATION}"
    gcloud artifacts repositories create "${GOOGLE_ARTIFACT_REPO}" \
        --repository-format=docker \
        --location="${ARTIFACT_LOCATION}" \
        --project="${GOOGLE_CLOUD_PROJECT}"
fi

echo ""
echo "Setup complete!"
echo ""
