# --- Dataplex: lake/zone registration for catalog + lineage ---

resource "google_dataplex_lake" "nova_retail" {
  name         = "nova-retail-lake"
  location     = var.region
  display_name = "Nova Retail Lake"
  description  = "Unified governance view over Nova Retail's raw and curated data"
}

resource "google_dataplex_zone" "raw_zone" {
  lake         = google_dataplex_lake.nova_retail.name
  location     = var.region
  name         = "raw-zone"
  display_name = "Raw Zone"
  type         = "RAW"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  discovery_spec {
    enabled = true
    schedule = "0 */6 * * *" # rescan every 6 hours for new/changed files
  }
}

resource "google_dataplex_zone" "curated_zone" {
  lake         = google_dataplex_lake.nova_retail.name
  location     = var.region
  name         = "curated-zone"
  display_name = "Curated Zone"
  type         = "CURATED"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  discovery_spec {
    enabled  = true
    schedule = "0 */6 * * *"
  }
}

# Assets: attach actual GCS buckets / BigQuery datasets to each zone

resource "google_dataplex_asset" "raw_zone_gcs" {
  name          = "raw-zone-gcs"
  location      = var.region
  lake          = google_dataplex_lake.nova_retail.name
  dataplex_zone = google_dataplex_zone.raw_zone.name

  resource_spec {
    name = "projects/${var.project_id}/buckets/${google_storage_bucket.raw_zone.name}"
    type = "STORAGE_BUCKET"
  }

  discovery_spec {
    enabled = true
  }
}

resource "google_dataplex_asset" "curated_zone_bq" {
  name          = "curated-zone-bq"
  location      = var.region
  lake          = google_dataplex_lake.nova_retail.name
  dataplex_zone = google_dataplex_zone.curated_zone.name

  resource_spec {
    name = "projects/${var.project_id}/datasets/${google_bigquery_dataset.curated.dataset_id}"
    type = "BIGQUERY_DATASET"
  }

  discovery_spec {
    enabled = true
  }
}
