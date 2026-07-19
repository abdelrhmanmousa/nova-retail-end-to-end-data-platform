#!/usr/bin/env bash
set -euo pipefail

# Run this ONCE per new GCP project, before terraform init.
# It authenticates your local gcloud + Terraform, and enables the APIs
# Terraform will need to create resources.

if [ -z "${1:-}" ]; then
  echo "Usage: ./bootstrap.sh <GCP_PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# echo "==> Setting active gcloud project to ${PROJECT_ID}"
# gcloud config set project "${PROJECT_ID}"

# echo "==> Authenticating your user for gcloud CLI (interactive login)"
# gcloud auth login

# echo "==> Authenticating Application Default Credentials (used by Terraform)"
# gcloud auth application-default login

echo "==> Skipping authentication (already completed)"

echo "==> Enabling required APIs (this can take a minute)"
gcloud services enable \
  storage.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  datastream.googleapis.com \
  artifactregistry.googleapis.com \
  composer.googleapis.com \
  container.googleapis.com \
  cloudbuild.googleapis.com \
  dataflow.googleapis.com \
  dataplex.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  --project "${PROJECT_ID}"

echo "==> Done. You can now run: ./scripts/run_terraform.sh plan"
