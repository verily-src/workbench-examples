"""Flask app demonstrating different flows for saving data to Verily Workbench.

This app provides three different workflows:
1. Direct GCS URI redirect - Pass through an existing GCS URI
2. TSV URL redirect - Pass through a URL to a TSV file containing GCS URIs
3. File upload with manifest - Upload a file to GCS, create a TSV manifest, then redirect
"""

from datetime import timedelta
import base64
import hashlib
import os
import secrets
import subprocess
import threading
import time

from dotenv import load_dotenv
from flask import Flask, redirect, render_template, request
from google.auth import impersonated_credentials
from google.cloud import storage
from werkzeug.utils import secure_filename
import google.auth
import requests

load_dotenv()

app = Flask(__name__)


# ============================================================================
# Helper Functions
# ============================================================================

def delete_github_file_after_delay(filename, delay_seconds):
    """Delete a file from GitHub after a specified delay.

    This function runs in a background thread to clean up manifest files
    after giving Workbench sufficient time to download them.

    Args:
        filename: Name of the file to delete from GitHub
        delay_seconds: Number of seconds to wait before deletion
    """
    def _delete():
        time.sleep(delay_seconds)

        github_api_url = f"https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/contents/{filename}"

        headers = {
            'Authorization': f'Bearer {GITHUB_TOKEN}',
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28'
        }

        # Get the file's SHA (required for deletion)
        get_response = requests.get(github_api_url, headers=headers)
        if get_response.status_code == 200:
            sha = get_response.json().get('sha')

            # Delete the file
            payload = {
                'message': f'Clean up manifest file {filename}',
                'sha': sha,
                'branch': GITHUB_REPO_BRANCH
            }

            requests.delete(github_api_url, headers=headers, json=payload)

    # Run deletion in background thread (non-daemon to ensure it completes)
    thread = threading.Thread(target=_delete, daemon=False)
    thread.start()


# ============================================================================
# Global Configuration
# ============================================================================

# Retrieve the current GCP project ID from gcloud configuration
_project_result = subprocess.run(
    ['gcloud', 'config', 'get-value', 'project'],
    capture_output=True,
    text=True,
    check=True
)
PROJECT_ID = _project_result.stdout.strip()

# Workbench import URL base
REDIRECT_URL_BASE = 'https://workbench.verily.com/import'

# GCS bucket where uploaded files are stored
GCS_BUCKET_NAME = os.environ.get('GCS_BUCKET_NAME', 'save-to-workbench')

# Service account used for signing GCS URLs
GCS_SERVICE_ACCOUNT_NAME = os.environ.get(
    'GCS_SERVICE_ACCOUNT_NAME',
    'gcs-uploader-and-signer'
)
GCS_SERVICE_ACCOUNT_EMAIL = (
    f'{GCS_SERVICE_ACCOUNT_NAME}@{PROJECT_ID}.iam.gserviceaccount.com'
)

# Signed URL expiration configuration
GCS_SIGNED_URL_EXPIRATION_HOURS = int(
    os.environ.get('GCS_SIGNED_URL_EXPIRATION_HOURS', '1')
)
GCS_SIGNED_URL_EXPIRATION = timedelta(hours=GCS_SIGNED_URL_EXPIRATION_HOURS)

# GitHub configuration for hosting manifest files
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')
GITHUB_REPO_BRANCH = os.environ.get('GITHUB_REPO_BRANCH', 'main')
GITHUB_MANIFEST_CLEANUP_DELAY_SECONDS = int(
    os.environ.get('GITHUB_MANIFEST_CLEANUP_DELAY_SECONDS', '30')
)


# ============================================================================
# Routes
# ============================================================================

@app.route('/')
def index():
    """Render the main page with options for different save-to-workbench flows.

    Returns:
        Rendered HTML template for the index page.
    """
    return render_template('index.html')


@app.route('/trigger-save-to-workbench-flow-gcs')
def trigger_save_to_workbench_flow():
    """Flow 1: Direct GCS URI redirect.

    Takes a GCS URI as a query parameter and redirects to Workbench import URL.

    Query Parameters:
        gcs_uri: GCS URI to import (e.g., gs://bucket/file.txt)

    Returns:
        HTTP 302 redirect to Workbench import page.
    """
    gcs_uri = request.args.get('gcs_uri', '')
    return redirect(f'{REDIRECT_URL_BASE}?url={gcs_uri}', code=302)


@app.route('/trigger-save-to-workbench-flow-tsv')
def trigger_save_to_workbench_flow_tsv():
    """Flow 2: TSV URL redirect.

    Takes a URL to a TSV file containing multiple GCS URIs and redirects to
    Workbench import URL with urlList parameter.

    Query Parameters:
        tsv_url: URL to TSV file containing GCS URIs

    Returns:
        HTTP 302 redirect to Workbench import page.
    """
    tsv_url = request.args.get('tsv_url', '')
    return redirect(f'{REDIRECT_URL_BASE}?urlList={tsv_url}', code=302)


@app.route('/trigger-save-to-workbench-flow-upload-manifest', methods=['POST'])
def trigger_save_to_workbench_flow_upload_manifest():
    """Flow 3: File upload with manifest file generation.

    Accepts a file upload via POST, uploads it to GCS, creates a TSV manifest
    file containing the file's signed URL, uploads the manifest to GitHub for
    public hosting, then redirects to Workbench import with the manifest URL.

    This flow involves:
    1. File upload to private GCS bucket
    2. Signed URL generation for the uploaded file
    3. TSV manifest file creation with TsvHttpData-1.0 format
    4. Manifest file upload to GitHub via API (with random filename for security)
    5. Background cleanup scheduled to delete manifest after configured delay
    6. Redirect to Workbench with GitHub-hosted manifest URL

    Form Parameters:
        file: File to upload

    Returns:
        HTTP 302 redirect to Workbench import page with manifest URL, or
        HTTP 400/500 error if file is missing or upload fails.
    """
    # Validate file was provided
    if 'file' not in request.files or request.files['file'].filename == '':
        return 'Error: No file selected', 400

    file = request.files['file']

    # Upload file to GCS
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME)
    filename = secure_filename(file.filename)
    blob = bucket.blob(filename)

    # Upload the file to GCS
    file_content = file.read()
    blob.upload_from_string(file_content)

    # Impersonate service account to generate signed URLs
    source_credentials, _ = google.auth.default()
    target_credentials = impersonated_credentials.Credentials(
        source_credentials=source_credentials,
        target_principal=GCS_SERVICE_ACCOUNT_EMAIL,
        target_scopes=['https://www.googleapis.com/auth/cloud-platform'],
        lifetime=3600
    )

    # Generate signed URL for the uploaded file
    file_signed_url = blob.generate_signed_url(
        version='v4',
        expiration=GCS_SIGNED_URL_EXPIRATION,
        method='GET',
        credentials=target_credentials
    )

    # Create TSV manifest file content (TsvHttpData-1.0 format with signed URL)
    manifest_content = f"TsvHttpData-1.0\n{file_signed_url}"

    # Upload manifest file to GitHub for public hosting (avoids org policy restrictions on public GCS buckets)
    # Generate a secure random filename to prevent guessing/enumeration
    random_token = secrets.token_urlsafe(32)
    manifest_hash = hashlib.sha256(random_token.encode()).hexdigest()[:16]
    manifest_filename = f"manifest-{manifest_hash}.tsv"

    # Upload manifest to GitHub using the GitHub API
    github_api_url = f"https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/contents/{manifest_filename}"

    headers = {
        'Authorization': f'Bearer {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    # Prepare the request to create the file (no need to check for existing since filename is unique)
    payload = {
        'message': f'Add manifest for {filename}',
        'content': base64.b64encode(manifest_content.encode()).decode(),
        'branch': GITHUB_REPO_BRANCH
    }

    # Upload the file to GitHub
    put_response = requests.put(github_api_url, headers=headers, json=payload)

    if put_response.status_code not in [200, 201]:
        return f'Error uploading manifest to GitHub: {put_response.text}', 500

    # Generate the raw GitHub URL for the manifest file
    manifest_public_url = f"https://raw.githubusercontent.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/{GITHUB_REPO_BRANCH}/{manifest_filename}"

    # Schedule background cleanup of the manifest file
    # This gives Workbench time to download the manifest before it's deleted
    delete_github_file_after_delay(manifest_filename, GITHUB_MANIFEST_CLEANUP_DELAY_SECONDS)

    return redirect(f'{REDIRECT_URL_BASE}?urlList={manifest_public_url}', code=302)


# ============================================================================
# Main
# ============================================================================

if __name__ == '__main__':
    app.run(debug=True)
