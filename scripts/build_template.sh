#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_template.sh <GCP_PROJECT_ID> <REGION>
#
# Builds the pipeline into a Docker image via Cloud Build, pushes it to the
# Artifact Registry repo Terraform created, then registers it as a Dataflow
# Flex Template. Run this once, and again any time main.py/parsing.py/etc change.

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Usage: ./build_template.sh <GCP_PROJECT_ID> <REGION>"
  exit 1
fi

PROJECT_ID="$1"
REGION="$2"
REPO="nova-retail-pipelines"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/clickstream-pipeline:latest"
TEMPLATE_GCS_PATH="gs://${PROJECT_ID}-pipeline-artifacts-dev/templates/clickstream-pipeline.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "==> Building and pushing image via Cloud Build: ${IMAGE}"

gcloud builds submit \
    "${PROJECT_ROOT}/Pipelines/dataflow" \
    --tag "${IMAGE}" \
    --project "${PROJECT_ID}"

echo "==> Registering Flex Template at ${TEMPLATE_GCS_PATH}"

gcloud dataflow flex-template build "${TEMPLATE_GCS_PATH}" \
    --image "${IMAGE}" \
    --sdk-language PYTHON \
    --metadata-file "${PROJECT_ROOT}/Pipelines/dataflow/metadata.json" \
    --project "${PROJECT_ID}"

echo "==> Done. Template ready at: ${TEMPLATE_GCS_PATH}"
echo "    Run it with: ./run_pipeline.sh ${PROJECT_ID} ${REGION}"
