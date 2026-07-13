resource "google_pubsub_topic" "clickstream_events" {
  name = "clickstream-events"
}

# Consumed by the Dataflow streaming pipeline
resource "google_pubsub_subscription" "clickstream_events_dataflow" {
  name  = "clickstream-events-dataflow-sub"
  topic = google_pubsub_topic.clickstream_events.id

  ack_deadline_seconds = 30

  expiration_policy {
    ttl = "" # never expires
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "60s"
  }
}
