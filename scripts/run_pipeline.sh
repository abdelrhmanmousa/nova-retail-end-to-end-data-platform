#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run_pipeline.sh <GCP_PROJECT_ID> <REGION>
#
# Launches a streaming Dataflow job from the Flex Template built by
# build_template.sh. Safe to re-run: each run gets a unique job name.

# if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
#   echo "Usage: ./run_pipeline.sh <GCP_PROJECT_ID> <REGION>"
#   exit 1
# fi

# PROJECT_ID="$1"
# REGION="$2"
PROJECT_ID="project-19093238-3ff7-407b-9e3"
REGION="us-central1"
TEMPLATE_GCS_PATH="gs://${PROJECT_ID}-pipeline-artifacts-dev/templates/clickstream-pipeline.json"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/nova-retail-pipelines/clickstream-pipeline:latest"
JOB_NAME="clickstream-pipeline-$(date +%Y%m%d-%H%M%S)"

echo "==> Launching Dataflow job: ${JOB_NAME} in ${REGION}"

gcloud dataflow flex-template run "${JOB_NAME}" \
  --template-file-gcs-location "${TEMPLATE_GCS_PATH}" \
  --region "${REGION}" \
  --project "${PROJECT_ID}" \
  --service-account-email "dataflow-runner@${PROJECT_ID}.iam.gserviceaccount.com" \
  --parameters input_subscription="projects/${PROJECT_ID}/subscriptions/clickstream-events-dataflow-sub" \
  --parameters output_path="gs://${PROJECT_ID}-raw-zone-dev/clickstream" \
  --parameters dead_letter_path="gs://${PROJECT_ID}-raw-zone-dev/clickstream_dead_letter" \
  --parameters window_size_minutes=2 \
  --parameters sdk_container_image="${IMAGE}" \
  --worker-machine-type="e2-standard-2" \
  --additional-experiments="number_of_worker_harness_threads=1"
  #--worker-zone="us-central1-f" \

echo "==> Job submitted. Check status:"
echo "    https://console.cloud.google.com/dataflow/jobs?project=${PROJECT_ID}"






# #!/usr/bin/env bash
# set -euo pipefail

# # Usage: ./run_pipeline.sh <GCP_PROJECT_ID> <REGION>
# #
# # Launches a streaming Dataflow job from the Flex Template built by
# # build_template.sh. Safe to re-run: each run gets a unique job name.

# if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
#   echo "Usage: ./run_pipeline.sh <GCP_PROJECT_ID> <REGION>"
#   exit 1
# fi

# PROJECT_ID="$1"
# REGION="$2"
# TEMPLATE_GCS_PATH="gs://${PROJECT_ID}-pipeline-artifacts-dev/templates/clickstream-pipeline.json"
# JOB_NAME="clickstream-pipeline-$(date +%Y%m%d-%H%M%S)"

# echo "==> Launching Dataflow job: ${JOB_NAME}"

# gcloud dataflow flex-template run "${JOB_NAME}" \
#   --template-file-gcs-location "${TEMPLATE_GCS_PATH}" \
#   --region "${REGION}" \
#   --project "${PROJECT_ID}" \
#   --service-account-email "dataflow-runner@${PROJECT_ID}.iam.gserviceaccount.com" \
#   --parameters input_subscription="projects/${PROJECT_ID}/subscriptions/clickstream-events-dataflow-sub" \
#   --parameters output_path="gs://${PROJECT_ID}-raw-zone-dev/clickstream" \
#   --parameters dead_letter_path="gs://${PROJECT_ID}-raw-zone-dev/clickstream_dead_letter" \
#   --parameters window_size_minutes=60 \
#   --worker-zone="us-central1-a" \
#   --additional-experiments="number_of_worker_harness_threads=1"

# echo "==> Job submitted. Check status:"
# echo "    https://console.cloud.google.com/dataflow/jobs?project=${PROJECT_ID}"