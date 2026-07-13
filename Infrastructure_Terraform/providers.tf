terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # For a solo portfolio project, local state is fine. If you want to practice
  # remote state (recommended if you ever collaborate or run this from CI),
  # create a GCS bucket manually first (chicken-and-egg problem) and uncomment:
  #
  # backend "gcs" {
  #   bucket = "REPLACE-WITH-A-BUCKET-YOU-CREATE-MANUALLY"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
