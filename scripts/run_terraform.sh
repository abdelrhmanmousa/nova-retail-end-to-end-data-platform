#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/run_terraform.sh plan
#   ./scripts/run_terraform.sh apply
#   ./scripts/run_terraform.sh destroy
#
# Assumes you've already run scripts/bootstrap.sh once, and that
# terraform.tfvars exists (copy terraform.tfvars.example -> terraform.tfvars
# and fill in real values first).

ACTION="${1:-plan}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../Infrastructure_Terraform"
cd "${TF_DIR}"

if [ ! -f "terraform.tfvars" ]; then
  echo "ERROR: terraform.tfvars not found in ${TF_DIR}"
  echo "Copy terraform.tfvars.example to terraform.tfvars and fill in real values first."
  exit 1
fi

echo "==> terraform init"
terraform init -upgrade

echo "==> terraform validate"
terraform validate

case "${ACTION}" in
  plan)
    echo "==> terraform plan"
    terraform plan -var-file="terraform.tfvars"
    ;;
  apply)
    echo "==> terraform plan (review before applying)"
    terraform plan -var-file="terraform.tfvars" -out=tfplan
    echo ""
    read -p "Apply this plan? [y/N] " confirm
    if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
      terraform apply tfplan
    else
      echo "Aborted."
      rm -f tfplan
      exit 0
    fi
    rm -f tfplan
    ;;
  destroy)
    echo "==> terraform destroy (this will tear down all managed resources)"
    read -p "Are you sure you want to destroy everything? [y/N] " confirm
    if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
      terraform destroy -var-file="terraform.tfvars"
    else
      echo "Aborted."
      exit 0
    fi
    ;;
  *)
    echo "Unknown action: ${ACTION}"
    echo "Usage: ./scripts/run_terraform.sh [plan|apply|destroy]"
    exit 1
    ;;
esac
