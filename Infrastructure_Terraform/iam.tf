# --- Service accounts (one per workload, least privilege) ---

resource "google_service_account" "dataflow_runner" {
  account_id   = "dataflow-runner"
  display_name = "Dataflow streaming pipeline runner"
}

resource "google_service_account" "composer_orchestrator" {
  account_id   = "composer-orchestrator"
  display_name = "Composer batch orchestration"
}

resource "google_service_account" "cloud_build_deployer" {
  account_id   = "cloud-build-deployer"
  display_name = "Cloud Build CI/CD deploy identity"
}

# --- Dataflow runner: needs to read Pub/Sub, write BigQuery, stage files in GCS ---

resource "google_pubsub_subscription_iam_member" "dataflow_pubsub_subscriber" {
  subscription = google_pubsub_subscription.clickstream_events_dataflow.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_pubsub_viewer" {
  subscription = google_pubsub_subscription.clickstream_events_dataflow.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_bigquery_dataset_iam_member" "dataflow_bq_staging_editor" {
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_project_iam_member" "dataflow_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_storage_bucket_iam_member" "dataflow_artifacts_access" {
  bucket = google_storage_bucket.pipeline_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_project_iam_member" "dataflow_worker_role" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

# --- Composer: needs to run batch jobs, read/write GCS zones, write BigQuery curated ---

resource "google_storage_bucket_iam_member" "composer_raw_zone_access" {
  bucket = google_storage_bucket.raw_zone.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

resource "google_storage_bucket_iam_member" "composer_curated_zone_access" {
  bucket = google_storage_bucket.curated_zone.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

resource "google_bigquery_dataset_iam_member" "composer_bq_curated_editor" {
  dataset_id = google_bigquery_dataset.curated.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

resource "google_bigquery_dataset_iam_member" "composer_bq_staging_viewer" {
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

# Datastream auto-creates this dataset (nova_retail_staging_public) outside
# of the google_bigquery_dataset.staging Terraform resource, so it needs its
# own explicit grant - easy to miss since it's not declared anywhere in
# bigquery.tf.

resource "google_bigquery_dataset_iam_member" "composer_bq_staging_public_viewer" {
  dataset_id = "nova_retail_staging_public"
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

resource "google_project_iam_member" "composer_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

resource "google_project_iam_member" "composer_worker_role" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

# --- Cloud Build: needs to push images and deploy Dataflow/Composer artifacts ---

resource "google_artifact_registry_repository_iam_member" "cloud_build_pusher" {
  location   = google_artifact_registry_repository.pipeline_images.location
  repository = google_artifact_registry_repository.pipeline_images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

resource "google_storage_bucket_iam_member" "cloud_build_artifacts_deploy" {
  bucket = google_storage_bucket.pipeline_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

resource "google_project_iam_member" "cloud_build_deploy_dataflow" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

# --- Cloud Build (default identity): on projects created after ~late 2024,
# Cloud Build runs under the Compute Engine default service account rather
# than a dedicated Cloud Build SA, and that account needs these roles granted
# explicitly or `gcloud builds submit` fails with a storage.objects.get error. ---

data "google_project" "current" {}

locals {
  compute_default_sa = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cloud_build_default_sa_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${local.compute_default_sa}"
}

resource "google_project_iam_member" "cloud_build_default_sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.compute_default_sa}"
}

resource "google_project_iam_member" "cloud_build_default_sa_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.compute_default_sa}"
}

# --- Datastream: GCP auto-provisions a service agent once the API is enabled.
# It needs BigQuery write access on the staging dataset to land CDC data. ---

resource "google_project_service_identity" "datastream_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "datastream.googleapis.com"
}

resource "google_bigquery_dataset_iam_member" "datastream_bq_staging_editor" {
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_project_service_identity.datastream_sa.email}"
}

resource "google_project_iam_member" "datastream_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_project_service_identity.datastream_sa.email}"
}


# --- Additions for CI/CD: cloud_build_deployer needs more than just
# artifactregistry.writer now, since cloudbuild.yaml has it do a lot more
# than push one image. ---

# Broad read access is required for `terraform plan` to describe existing
# resources across BigQuery, Pub/Sub, Datastream, Composer, etc. This is a
# deliberate, scoped trade-off: Viewer is read-only (cannot create/modify/
# delete anything), which is why it's acceptable even though it's broad -
# the alternative is hand-picking a dozen individual *.viewer roles across
# every service this project touches, for no real security gain over the
# built-in read-only role.
resource "google_project_iam_member" "cloud_build_deployer_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

# Needed because cloudbuild.yaml's build steps call `gcloud builds submit`
# themselves (reusing the same scripts you run locally) - that's a build
# triggering a nested build, which requires this role on the outer build's
# service account.
resource "google_project_iam_member" "cloud_build_deployer_builds_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

# Composer creates its own DAG bucket outside of Terraform's control (only
# its name is knowable via the dag_gcs_prefix output), so this needs a
# separate explicit grant, same pattern as the Datastream-created dataset.
locals {
  composer_dag_bucket_name = replace(
    replace(google_composer_environment.batch_orchestrator.config[0].dag_gcs_prefix, "gs://", ""),
    "/dags", ""
  )
}

resource "google_storage_bucket_iam_member" "cloud_build_deployer_dag_bucket" {
  bucket = local.composer_dag_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

# roles/viewer (granted above) covers reading BigQuery data/metadata, but
# NOT running query jobs - dbt test actually executes queries against
# BigQuery, which needs this explicitly.
resource "google_project_iam_member" "cloud_build_deployer_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}

# Without this, the build can't write its own logs to Cloud Logging - which
# also means step failures show no output, making them impossible to debug.
resource "google_project_iam_member" "cloud_build_deployer_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}
