#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -f ".env" ]]; then
    echo "Loading configuration from .env file..."
    set -a
    source .env
    set +a
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    1>&2 echo "ERROR: Not authenticated with gcloud"
    1>&2 echo "Please run: gcloud auth login"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
readonly PROJECT_ID

if [[ -z "${PROJECT_ID}" ]]; then
    1>&2 echo "ERROR: No default project set in gcloud config"
    1>&2 echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: ${PROJECT_ID}"

readonly GCS_BUCKET_NAME="${GCS_BUCKET_NAME:-save-to-workbench}"
readonly GCS_BUCKET_LOCATION="${GCS_BUCKET_LOCATION:-us-central1}"
readonly GCS_SERVICE_ACCOUNT_NAME="${GCS_SERVICE_ACCOUNT_NAME:-gcs-uploader-and-signer}"
readonly GCS_SERVICE_ACCOUNT_EMAIL="${GCS_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Configuration:"
echo "  Bucket: gs://${GCS_BUCKET_NAME}"
echo "  Service Account: ${GCS_SERVICE_ACCOUNT_EMAIL}"
echo ""

echo "Enabling IAM Service Account Credentials API..."
gcloud services enable iamcredentials.googleapis.com --project="${PROJECT_ID}" --quiet

if gcloud storage buckets describe "gs://${GCS_BUCKET_NAME}" --project="${PROJECT_ID}" &>/dev/null; then
    echo "Bucket already exists: gs://${GCS_BUCKET_NAME}"
else
    echo "Creating GCS bucket: gs://${GCS_BUCKET_NAME}"
    BUCKET_CREATE_CMD=(gcloud storage buckets create "gs://${GCS_BUCKET_NAME}"
        --project="${PROJECT_ID}"
        --location="${GCS_BUCKET_LOCATION}"
        --uniform-bucket-level-access)

    if [[ -f "lifecycle.json" ]]; then
        BUCKET_CREATE_CMD+=(--lifecycle-file="lifecycle.json")
    fi

    "${BUCKET_CREATE_CMD[@]}"
fi

if gcloud iam service-accounts describe "${GCS_SERVICE_ACCOUNT_EMAIL}" --project="${PROJECT_ID}" &>/dev/null; then
    echo "Service account already exists: ${GCS_SERVICE_ACCOUNT_EMAIL}"
else
    echo "Creating service account: ${GCS_SERVICE_ACCOUNT_EMAIL}"
    gcloud iam service-accounts create "$GCS_SERVICE_ACCOUNT_NAME" \
        --display-name="GCS Uploader and Signer" \
        --project="${PROJECT_ID}"
fi

echo "Granting storage.objectAdmin role to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${GCS_SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/storage.objectAdmin" \
    --quiet

echo "Granting iam.serviceAccountTokenCreator role to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${GCS_SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --quiet

USER_EMAIL="$(gcloud config get-value account 2>/dev/null)"
readonly USER_EMAIL

if [[ -z "${USER_EMAIL}" ]]; then
    1>&2 echo "ERROR: Could not determine current user email"
    exit 1
fi

echo "Granting ${USER_EMAIL} permission to impersonate service account..."
gcloud iam service-accounts add-iam-policy-binding "${GCS_SERVICE_ACCOUNT_EMAIL}" \
    --member="user:${USER_EMAIL}" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --project="${PROJECT_ID}" \
    --quiet

echo ""
echo "Setup complete!"
echo ""
echo "Next step:"
echo "  ./run-app.sh"
