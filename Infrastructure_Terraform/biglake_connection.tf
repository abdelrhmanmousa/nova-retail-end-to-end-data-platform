# --- BigLake connection: upgrades plain external tables to BigLake ---
#
# Gives the external tables (clickstream, supplier_catalog, currency_rates)
# metadata caching (addresses the small-file performance concern from
# earlier) and makes them eligible for the same fine-grained/row-column
# security as native tables, via Dataplex/Data Catalog.

resource "google_bigquery_connection" "biglake" {
  connection_id = "nova-retail-biglake"
  location      = var.region

  cloud_resource {}
}

# BigLake connections get their own auto-provisioned service account -
# it needs to actually read the GCS files it's pointing at.
resource "google_storage_bucket_iam_member" "biglake_connection_reader" {
  bucket = google_storage_bucket.raw_zone.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_bigquery_connection.biglake.cloud_resource[0].service_account_id}"
}
