resource "google_storage_bucket" "raw_zone" {
  name                        = "${var.project_id}-raw-zone-${var.environment}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true # convenient for a demo project; remove for anything real

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "curated_zone" {
  name                        = "${var.project_id}-curated-zone-${var.environment}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Used later to hold Composer DAGs, Dataflow Flex Template specs, etc.
resource "google_storage_bucket" "pipeline_artifacts" {
  name                        = "${var.project_id}-pipeline-artifacts-${var.environment}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}
