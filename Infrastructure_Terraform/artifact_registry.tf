resource "google_artifact_registry_repository" "pipeline_images" {
  location      = var.region
  repository_id = "nova-retail-pipelines"
  format        = "DOCKER"
  description   = "Docker images for Dataflow Flex Templates and other pipeline jobs"
}
