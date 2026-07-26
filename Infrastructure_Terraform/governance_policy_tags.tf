# --- PII governance: policy tag taxonomy ---
#
# This defines the taxonomy/tag only. The tag gets APPLIED to actual
# columns via dbt's policy_tags config (see dbt_nova_retail/models/marts/
# schema.yml) - not here - because email lives in dim_customers, a
# dbt-managed table, not a Terraform-managed one.

resource "google_data_catalog_taxonomy" "nova_retail_pii" {
  region                 = var.region
  display_name           = "nova_retail_pii"
  description            = "PII classification for Nova Retail"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "pii_email" {
  taxonomy     = google_data_catalog_taxonomy.nova_retail_pii.id
  display_name = "PII - Email"
  description  = "Customer email addresses - direct query access restricted"
}

# Only the composer_orchestrator SA (which runs dbt) and you, the project
# owner, can read the actual raw email column. Add other principals here
# as needed (e.g. an analyst group) - anyone NOT granted this role sees
# NULL when querying email directly, even if they have BigQuery access to
# the table otherwise.
resource "google_data_catalog_policy_tag_iam_member" "pii_email_reader" {
  policy_tag = google_data_catalog_policy_tag.pii_email.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = "serviceAccount:${google_service_account.composer_orchestrator.email}"
}

# --- Authorized view: safe, email-free access to customer dimension ---
# Anyone with access to this dataset/view sees everything EXCEPT email,
# with no special policy-tag grant needed - this is the "safe by default"
# path most consumers (e.g. Looker Studio, analysts) should use.

resource "google_bigquery_dataset" "reporting" {
  dataset_id  = "nova_retail_reporting"
  location    = var.region
  description = "Safe, PII-free views for BI/analyst consumption"
}

resource "google_bigquery_table" "customers_safe_view" {
  dataset_id          = google_bigquery_dataset.reporting.dataset_id
  table_id            = "customers_safe"
  deletion_protection = false

  view {
    query          = <<-SQL
      SELECT customer_id, name, country, signup_date
      FROM `${var.project_id}.${google_bigquery_dataset.curated.dataset_id}.dim_customers`
    SQL
    use_legacy_sql = false
  }
}

# This is what makes it an "authorized view": grants the VIEW itself read
# access to the source dataset, so people granted access to the view can
# query it without needing any direct grant on nova_retail_curated (or the
# policy-tagged email column) at all.
resource "google_bigquery_dataset_access" "curated_authorizes_safe_view" {
  dataset_id = google_bigquery_dataset.curated.dataset_id

  view {
    project_id = var.project_id
    dataset_id = google_bigquery_dataset.reporting.dataset_id
    table_id   = google_bigquery_table.customers_safe_view.table_id
  }
}
