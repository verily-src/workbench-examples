# Egress Event Notification Service

A Cloud Run service that handles egress event notifications from Google Cloud Workbench environments and sends email alerts.

## Features

- REST API endpoint for receiving egress event data
- Email notifications
- Authenticated access with JWT token verification
- Health check endpoint for monitoring
- Containerized deployment on Google Cloud Run

## Files

- **main.py**: Flask application with REST endpoints and JWT authentication
- **email_notifier.py**: Email notification handler
- **Dockerfile**: Container configuration for Cloud Run
- **requirements.txt**: Python dependencies

## API Endpoints

### `POST /egress-notification`
Receives and processes egress event notifications.

**Required Fields:**
- `incidentCount`: Number of incidents
- `vwbWorkspaceId`: Workbench workspace ID
- `vwbEgressEventId`: Egress event ID
- `egressMib`: Amount of egress data in MiB
- `egressMibThreshold`: Threshold value in MiB
- `gcpProjectId`: GCP project ID
- `vmName`: Virtual machine name
- `timeWindowDuration`: Duration in seconds
- `timeWindowStart`: Unix epoch timestamp in milliseconds
- `userEmail`: User email address

**Example Request:**
```bash
curl -X POST https://your-service-url/egress-notification \
  -H "Content-Type: application/json" \
  -d '{
    "incidentCount": 1,
    "vwbWorkspaceId": "ws-12345",
    "vwbEgressEventId": "evt-67890",
    "egressMib": 1024,
    "egressMibThreshold": 500,
    "gcpProjectId": "my-project",
    "vmName": "workbench-vm-1",
    "timeWindowDuration": 3600,
    "timeWindowStart": 1698364800000,
    "userEmail": "user@example.com"
  }'
```

### `GET /health`
Health check endpoint for monitoring.

## Setup

### Environment Variables

Set your environment variables:
```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export SERVICE_ACCOUNT="egress-notifier@${PROJECT_ID}.iam.gserviceaccount.com"
export INVOKER_SA="cloud-run-invoker-sa@${PROJECT_ID}.iam.gserviceaccount.com"
export ADMIN_EMAILS="comma separated list of admin emails (optional)"
```

### Service Account Setup

**NOTE: You only need to set up service accounts once!**

Create a service account for Cloud Run:
```bash
gcloud iam service-accounts create egress-notifier \
  --display-name="Egress Notification Service Account" \
  --project=YOUR_PROJECT_ID
```

Create an "invoker" service account for testing requests:
```bash
gcloud iam service-accounts create cloud-run-invoker-sa \
  --display-name="Cloud Run Invoker for Testing" \
  --project=YOUR_PROJECT_ID
```

Grant invoker permissions to the invoker service account (for testing requests):
```bash
gcloud run services add-iam-policy-binding egress-notification-service \
    --member="serviceAccount:${INVOKER_SA}" \
    --role="roles/run.invoker" \
    --region=us-central1
```

Grant yourself the ability to create tokens for the invoker service account:
```bash
gcloud iam service-accounts add-iam-policy-binding \
    "${INVOKER_SA}" \
    --member="user:YOUR-EMAIL-ADDRESS" \
    --role="roles/iam.serviceAccountTokenCreator"
```
### Deploy to Cloud Run

1. Deploy the service:
```bash
gcloud run deploy egress-notification-service \
  --source . \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --platform managed \
  --service-account "${SERVICE_ACCOUNT}" \
  --set-env-vars "ADMIN_EMAILS=${ADMIN_EMAILS}" \
  --no-allow-unauthenticated \
  --max-instances 10 \
  --memory 512Mi \
  --timeout 60
```

2. Successful deployment of the Cloud Run service will return a service URL.  Save this URL in an environment variable:
```bash
export CR_URL="url returned from step 1"
```

3. Test authenticated access:
```bash
# Get an identity token, impersonating the invoker service account:
TOKEN=$(gcloud auth print-identity-token \
    --audiences="${CR_URL}" \
    --impersonate-service-account="${INVOKER_SA}")

# Make an authenticated request
curl -X POST "${CR_URL}/egress-notification" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "incidentCount": 1,
    "vwbWorkspaceId": "ws-12345",
    "vwbEgressEventId": "evt-67890",
    "egressMib": 1024,
    "egressMibThreshold": 500,
    "gcpProjectId": "my-project",
    "vmName": "workbench-vm-1",
    "timeWindowDuration": 3600,
    "timeWindowStart": 1762278562857,
    "userEmail": "jrandomuser@sciencelab.org"
  }'
```
