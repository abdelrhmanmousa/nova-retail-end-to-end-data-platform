variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Default GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name, used as a resource name suffix"
  type        = string
  default     = "dev"
}

variable "cloudsql_instance_connection_name" {
  description = "Connection name of the existing Cloud SQL instance (project:region:instance)"
  type        = string
}

variable "cloudsql_public_ip" {
  description = "Public IP address of the existing Cloud SQL instance, used by Datastream"
  type        = string
}

variable "cloudsql_database" {
  description = "Database name inside the Cloud SQL instance"
  type        = string
  default     = "nova_retail"
}

variable "cloudsql_user" {
  description = "Postgres user Datastream will use to read via CDC"
  type        = string
  default     = "datastream_reader"
}

variable "cloudsql_password" {
  description = "Password for the Datastream Postgres user"
  type        = string
  sensitive   = true
}
