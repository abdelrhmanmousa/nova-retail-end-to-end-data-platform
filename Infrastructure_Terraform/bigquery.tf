resource "google_bigquery_dataset" "staging" {
  dataset_id  = "nova_retail_staging"
  location    = var.region
  description = "Raw/lightly-cleaned data landed by Datastream and Dataflow, before modeling"
}

resource "google_bigquery_dataset" "curated" {
  dataset_id  = "nova_retail_curated"
  location    = var.region
  description = "Modeled, business-ready tables for BI (star schema / aggregates)"
}
