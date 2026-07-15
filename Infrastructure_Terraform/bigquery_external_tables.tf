resource "google_bigquery_table" "clickstream_external" {
  dataset_id          = google_bigquery_dataset.staging.dataset_id
  table_id            = "clickstream_events"
  deletion_protection = false

  external_data_configuration {
    autodetect    = true
    source_format = "PARQUET"
    source_uris   = ["gs://${google_storage_bucket.raw_zone.name}/clickstream/*"]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${google_storage_bucket.raw_zone.name}/clickstream/"
    }
  }
}
resource "google_bigquery_table" "supplier_catalog_external" {
  dataset_id          = google_bigquery_dataset.staging.dataset_id
  table_id            = "supplier_catalog"
  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.raw_zone.name}/supplier_catalog/*"]
    autodetect    = true

    csv_options {
      skip_leading_rows = 1
      quote = "\""
    }

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${google_storage_bucket.raw_zone.name}/supplier_catalog/"
    }
  }
}

resource "google_bigquery_table" "currency_rates_external" {
  dataset_id          = google_bigquery_dataset.staging.dataset_id
  table_id            = "currency_rates"
  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.raw_zone.name}/currency_rates/*"]
    autodetect    = true

    csv_options {
      skip_leading_rows = 1
      quote = "\""
    }

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${google_storage_bucket.raw_zone.name}/currency_rates/"
    }
  }
}
