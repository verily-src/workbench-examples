# Save to Workbench Flow Proof of Concept

## Overview

This proof of concept demonstrates how external tools can initiate a "Save to Workbench" flow by redirecting users to Verily Workbench's `/import` endpoint.

The Workbench `/import` endpoint is based on the [Google Cloud Storage Transfer Service](https://docs.cloud.google.com/storage-transfer/docs/overview).

This implements three different approaches to importing data into Workbench, each suited for different use cases and security requirements, ordered from least to most complex.

## Quick Start

For a quick demo of the application:

1. **Run the application**:
   ```bash
   ./run-app.sh
   ```

2. **Open your browser** and navigate to `http://127.0.0.1:5000`

**Note:** Methods 1 and 2 work immediately. Method 3 requires GCS and GitHub setup (see [Infrastructure Setup](#infrastructure-setup)).

## Methods

### Method 1: Direct Google Cloud Storage URI

Import directly from publicly accessible GCS buckets.

**Single file**:
```
https://workbench.verily.com/import?url=gs://bucket/path/to/file.csv
```

**Multiple files**:
```
https://workbench.verily.com/import?url=gs://bucket1/file1.txt&url=gs://bucket2/file2.txt
```

**Requirements:**
- GCS URIs must be publicly accessible or accessible to the user's Workbench account

### Method 2: TSV Manifest URL

Import one or more files using a publicly accessible TSV manifest file containing file URLs.

**Usage**:
```
https://workbench.verily.com/import?urlList=https://example.com/manifest.tsv
```

**How it works:**
1. User provides a URL to a publicly accessible TSV manifest file
2. Application redirects to Workbench with the manifest URL
3. Workbench downloads the manifest and imports all listed files

**Requirements:**
- Manifest file URL must be publicly accessible via HTTP/HTTPS
- URLs within the manifest must be accessible (can be public URLs or signed URLs for private resources)
- URLs should be in UTF-8 lexicographical order

**Key Benefit:** The manifest file can contain signed URLs to facilitate transfer of resources from private GCS buckets, providing time-limited access without making buckets public.

### Method 3: Upload with Auto-Generated Manifest

End-to-end workflow that handles file upload, signed URL generation, manifest creation, and redirect. A production implementation of this method would likely substitute the file upload with an API response and GitHub with a publicly-accessible cloud storage bucket with a short time-to-live (TTL) (e.g. 30 seconds, just long enough to allow the user to complete through the Workbench flow).

**How it works:**
1. User uploads file via web form → Stored in private GCS bucket
2. Backend generates time-limited signed URL for the file
3. Backend creates TSV manifest containing the signed URL → Uploaded to GitHub with random filename
4. Backend schedules automatic cleanup of manifest file (default: 30 seconds)
5. User redirected to Workbench with GitHub-hosted manifest URL

**Security features:**
- Data files remain in private GCS bucket
- Signed URLs provide time-limited access
- Manifest filenames are cryptographically random to prevent enumeration
- Automatic manifest cleanup after successful import

## Manifest File Specification

Both Method 2 and Method 3 use the TSV manifest format based on the [Google Cloud Storage Transfer Service URL list specification](https://docs.cloud.google.com/storage-transfer/docs/create-url-list).

### Format

- **Line 1:** `TsvHttpData-1.0` (required header)
- **Subsequent lines:** Tab-separated values with:
  - URL (required)
  - File size in bytes (optional)
  - Base64-encoded MD5 checksum (optional)

### Example

```tsv
TsvHttpData-1.0
https://example.com/file1.txt	1357	wHENa08V36iPYAsOa2JAdw==
https://example.com/file2.txt	2048	x1bHN9kL8fR3qT9vWmZpEg==
```

### Using Signed URLs

Manifest files can contain signed URLs to provide secure, time-limited access to files in private GCS buckets:

```tsv
TsvHttpData-1.0
https://storage.googleapis.com/bucket/file.txt?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=...
```

Method 3 automatically generates manifests with signed URLs.

## Configuration Reference (Method 3 only)

### GCS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GCS_BUCKET_NAME` | `save-to-workbench` | GCS bucket name for uploaded files |
| `GCS_BUCKET_LOCATION` | `us-central1` | GCS bucket region |
| `GCS_SERVICE_ACCOUNT_NAME` | `gcs-uploader-and-signer` | Service account for signing URLs |
| `GCS_SIGNED_URL_EXPIRATION_HOURS` | `1` | Hours until signed URLs expire |

### GitHub Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_TOKEN` | *(required)* | Personal access token with `repo` scope |
| `GITHUB_REPO_OWNER` | *(required)* | GitHub username or organization |
| `GITHUB_REPO_NAME` | *(required)* | Repository name for manifest files |
| `GITHUB_REPO_BRANCH` | `main` | Branch to use for manifest files |
| `GITHUB_MANIFEST_CLEANUP_DELAY_SECONDS` | `30` | Seconds before deleting manifest files |

### Configuration File

Create a `.env` file in the project root:

```bash
cp .env.example .env
# Edit .env with your values
```

## Infrastructure Setup (Method 3 only)

### Prerequisites

- Python 3.x
- Google Cloud SDK (gcloud)
- GCS bucket and service account
- GitHub repository and token

### GCS Infrastructure Setup

The `setup-infra.sh` script automates GCS infrastructure provisioning:

```bash
./setup-infra.sh
```

**What it does:**
- Creates a GCS bucket with specified name and location
- Creates a service account with appropriate permissions
- Grants the service account `storage.objectAdmin` role for managing files
- Grants the service account `iam.serviceAccountTokenCreator` role for signing URLs
- Grants current user permission to impersonate the service account

**Manual setup alternative:**
If you prefer manual setup, create:
1. A GCS bucket for file storage
2. A service account with `storage.objectAdmin` and `iam.serviceAccountTokenCreator` roles
3. IAM bindings allowing your user to impersonate the service account

### GitHub Setup

1. **Create a repository** to host manifest files (can be public or private)

2. **Generate a personal access token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a descriptive name (e.g., "save-to-workbench-manifest")
   - Select the `repo` scope (full control of private repositories)
   - Generate and copy the token

3. **Configure in `.env`**:
   ```bash
   GITHUB_TOKEN=your_token_here
   GITHUB_REPO_OWNER=your_username
   GITHUB_REPO_NAME=your_repo_name
   GITHUB_REPO_BRANCH=main
   ```
