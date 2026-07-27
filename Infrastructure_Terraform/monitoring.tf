# --- Monitoring: notification channel, dashboard, and alert policies ---

variable "alert_email" {
  description = "Email address to receive monitoring alerts"
  type        = string
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Nova Retail Alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# --- Alert 1: Dataflow streaming job not running ---
# Fires if the "running" metric for the clickstream job drops (job crashed,
# was cancelled unexpectedly, or failed to start).
resource "google_monitoring_alert_policy" "dataflow_job_not_running" {
  display_name = "Clickstream Dataflow job not running"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.email.id]

  conditions {
    display_name = "No running Dataflow job with expected job name"

    condition_threshold {
      filter          = "resource.type=\"dataflow_job\" AND metric.type=\"dataflow.googleapis.com/job/is_failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "The clickstream Dataflow streaming job has failed. Check the Dataflow console for the job status and worker logs."
    mime_type = "text/markdown"
  }
}

# --- Alert 2: Pub/Sub backlog growing (streaming pipeline falling behind) ---
resource "google_monitoring_alert_policy" "pubsub_backlog_high" {
  display_name = "Clickstream Pub/Sub backlog too high"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.email.id]

  conditions {
    display_name = "Unacked message count above threshold"

    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${google_pubsub_subscription.clickstream_events_dataflow.name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1000
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "The clickstream Pub/Sub subscription has over 1000 undelivered messages for 10+ minutes - the Dataflow pipeline may be falling behind or stalled."
    mime_type = "text/markdown"
  }
}

# Alert 3: Airflow DAG task failures (via log monitoring)
# --- Alert 3: Composer DAG failures (More stable version) ---
resource "google_monitoring_alert_policy" "composer_dag_failed" {
  display_name = "Nova Retail batch DAG failed"
  combiner      = "OR"
  notification_channels = [google_monitoring_notification_channel.email.id]

  conditions {
    display_name = "Airflow task failures"

    condition_threshold {
      # Use cloud_composer_environment and dag_run_count
      filter          = "resource.type=\"cloud_composer_environment\" AND metric.type=\"composer.googleapis.com/environment/dag_run_count\" AND metric.labels.dag_state=\"failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s" 

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "An Airflow task has failed in the Composer environment. Check the Airflow UI for logs."
    mime_type = "text/markdown"
  }
}

# --- Dashboard: single view of pipeline health ---
resource "google_monitoring_dashboard" "nova_retail_overview" {
  dashboard_json = jsonencode({
    displayName = "Nova Retail - Pipeline Overview"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "Pub/Sub - Undelivered Messages (clickstream backlog)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${google_pubsub_subscription.clickstream_events_dataflow.name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
                  aggregation = {
                    alignmentPeriod  = "300s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
          }
        },
        {
          title = "Dataflow - System Lag"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"dataflow_job\" AND metric.type=\"dataflow.googleapis.com/job/system_lag\""
                  aggregation = {
                    alignmentPeriod  = "300s"
                    perSeriesAligner = "ALIGN_MAX"
                  }
                }
              }
            }]
          }
        },
        {
          title = "BigQuery - Bytes Scanned (Query Volume)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"global\" AND metric.type=\"bigquery.googleapis.com/query/scanned_bytes\""
                  aggregation = {
                    alignmentPeriod  = "300s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
            }]
          }
        },
       {
          title = "Composer - DAG Run Count by State"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_composer_workflow\" AND metric.type=\"composer.googleapis.com/workflow/run_count\""
                  aggregation = {
                    alignmentPeriod    = "300s"
                    perSeriesAligner   = "ALIGN_SUM"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields      = ["metric.label.state"]
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}

output "monitoring_dashboard_url" {
  value = "https://console.cloud.google.com/monitoring/dashboards/custom/${element(split("/", google_monitoring_dashboard.nova_retail_overview.id), 1)}?project=${var.project_id}"
}
