# --- Prerequisites (manual, one-time, not managed by Terraform) ---
#
# 1. On the Cloud SQL instance, enable logical replication:
#      Console: Edit instance -> Flags -> add "cloudsql.logical_decoding" = on
#    (requires an instance restart)
#
# 2. Connect via psql and create a dedicated replication user + publication:
#      CREATE USER datastream_reader WITH REPLICATION PASSWORD '...';
#      GRANT SELECT ON ALL TABLES IN SCHEMA public TO datastream_reader;
#      CREATE PUBLICATION datastream_pub FOR ALL TABLES;
#
# 3. Allow Datastream to reach the instance: add Datastream's IP ranges to the
#    Cloud SQL instance's Authorized Networks (Console -> Connections -> Networking).
#    Since the instance isn't Terraform-managed yet, do this manually for now.
#
# 4. Enable the Datastream API:
#      gcloud services enable datastream.googleapis.com

resource "google_datastream_connection_profile" "postgres_source" {
  display_name         = "nova-retail-postgres-source"
  connection_profile_id = "nova-retail-postgres-source"
  location              = var.region

  postgresql_profile {
    hostname = var.cloudsql_public_ip
    port     = 5432
    username = var.cloudsql_user
    password = var.cloudsql_password
    database = var.cloudsql_database
  }
}

resource "google_datastream_connection_profile" "bigquery_destination" {
  display_name         = "nova-retail-bigquery-destination"
  connection_profile_id = "nova-retail-bigquery-destination"
  location              = var.region

  bigquery_profile {}
}

resource "google_datastream_stream" "postgres_to_bigquery" {
  stream_id     = "nova-retail-cdc-stream"
  display_name  = "nova-retail-cdc-stream"
  location      = var.region
  desired_state = "RUNNING"

  source_config {
    source_connection_profile = google_datastream_connection_profile.postgres_source.id

    postgresql_source_config {
      publication      = "datastream_pub"
      replication_slot = "datastream_slot"

      include_objects {
        postgresql_schemas {
          schema = "public"
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bigquery_destination.id

    bigquery_destination_config {
      source_hierarchy_datasets {
        dataset_template {
          location = var.region
          # lands each replicated table into the staging dataset
          dataset_id_prefix = "${google_bigquery_dataset.staging.dataset_id}_"
        }
      }
    }
#   bigquery_destination_config {
#   single_target_dataset {
#     dataset_id = "project-19093238-3ff7-407b-9e3:nova_retail_staging"
#   }
# }



  }

  backfill_all {}
}
