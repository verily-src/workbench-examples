#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if [[ ! -f ".venv/bin/activate" ]]; then
    echo "Creating virtual environment..."
    rm -rf .venv
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install -r requirements.txt -q

if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo "WARNING: Google Cloud credentials not found"
    echo "Method 3 (Google Cloud Storage Signed URL) requires authentication:"
    echo "  gcloud auth application-default login"
    echo ""
fi

echo "Starting Flask application at http://127.0.0.1:5000"
echo "Press Ctrl+C to stop"
echo ""

python app.py
