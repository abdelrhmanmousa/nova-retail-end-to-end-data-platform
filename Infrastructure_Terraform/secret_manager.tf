# --- Secret Manager: Cloud SQL password ---
#
# Create the secret's VALUE manually, once (never commit the real password
# anywhere):
#   echo -n "your-actual-password" | gcloud secrets versions add \
#     cloudsql-datastream-password --data-file=- --project=<PROJECT_ID>

resource "google_secret_manager_secret" "cloudsql_password" {
  secret_id = "cloudsql-datastream-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "cloud_build_deployer_secret_accessor" {
  secret_id = google_secret_manager_secret.cloudsql_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_build_deployer.email}"
}
