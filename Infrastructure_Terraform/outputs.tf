output "raw_zone_bucket" {
  value = google_storage_bucket.raw_zone.name
}

output "curated_zone_bucket" {
  value = google_storage_bucket.curated_zone.name
}

output "pipeline_artifacts_bucket" {
  value = google_storage_bucket.pipeline_artifacts.name
}

output "clickstream_topic" {
  value = google_pubsub_topic.clickstream_events.name
}

output "clickstream_subscription" {
  value = google_pubsub_subscription.clickstream_events_dataflow.name
}

output "bigquery_staging_dataset" {
  value = google_bigquery_dataset.staging.dataset_id
}

output "bigquery_curated_dataset" {
  value = google_bigquery_dataset.curated.dataset_id
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.pipeline_images.name
}
