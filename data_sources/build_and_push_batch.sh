#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_and_push_batch.sh <GCP_PROJECT_ID> <REGION>
# Builds/pushes the batch-producers image via Cloud Build (not local docker
# build+push) - avoids relying on local upload bandwidth, which can time out
# on slower/unstable connections.

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Usage: ./build_and_push_batch.sh <GCP_PROJECT_ID> <REGION>"
  exit 1
fi

PROJECT_ID="$1"
REGION="$2"
REPO="nova-retail-pipelines"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/batch-producers:latest"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "==> Building and pushing via Cloud Build: ${IMAGE}"
gcloud builds submit \
  --config cloudbuild_batch.yaml \
  --substitutions "_IMAGE=${IMAGE}" \
  --project "${PROJECT_ID}" \
  .

echo "==> Done: ${IMAGE}"