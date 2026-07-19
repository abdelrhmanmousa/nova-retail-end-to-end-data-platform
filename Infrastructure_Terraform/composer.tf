# --- Cloud Composer 2 environment for batch orchestration ---
#
# COST WARNING: unlike almost everything else in this project, Composer
# bills continuously while the environment exists (not pay-per-use). A SMALL
# environment is roughly $300-400/month if left running. For a portfolio
# project, create it when you want to demo/develop against it, and delete it
# (`terraform destroy -target=google_composer_environment.batch_orchestrator`)
# when you're done for the day. The DAG code itself is safe in your repo -
# recreating the environment just means a ~20-40 min wait, not lost work.

resource "google_project_service_identity" "composer_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "composer.googleapis.com"
}

# Required for Composer 2 to manage the underlying GKE-based infrastructure
resource "google_project_iam_member" "composer_service_agent_ext" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:${google_project_service_identity.composer_sa.email}"
}

resource "google_composer_environment" "batch_orchestrator" {
  name    = "nova-retail-orchestrator"
  region  = var.region
  project = var.project_id

  config {
    software_config {
      image_version = "composer-2.17.6-airflow-2.11.1"

      pypi_packages = {
        "apache-airflow-providers-cncf-kubernetes" = ""
      }

      env_variables = {
        GCP_PROJECT_ID       = var.project_id
        RAW_ZONE_BUCKET      = google_storage_bucket.raw_zone.name
        CURATED_ZONE_BUCKET  = google_storage_bucket.curated_zone.name
        DBT_IMAGE             = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.pipeline_images.repository_id}/dbt-nova-retail:latest"
      }
    }

    node_config {
      service_account = google_service_account.composer_orchestrator.email
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }
  }

  depends_on = [
    google_project_iam_member.composer_service_agent_ext,
    google_project_iam_member.composer_worker_role,
  ]
}

output "composer_dag_bucket" {
  value       = google_composer_environment.batch_orchestrator.config[0].dag_gcs_prefix
  description = "GCS path to upload DAG files to"
}

output "composer_airflow_uri" {
  value = google_composer_environment.batch_orchestrator.config[0].airflow_uri
}
