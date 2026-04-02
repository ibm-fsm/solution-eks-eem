variable "eem_api_url" {
  type        = string
  description = "The Admin URL of the EEM Manager (e.g., https://eem.eem-server-test.local.test/admin)"
}

variable "access_token" {
  type        = string
  description = "The Bearer token for EEM API authentication"
  sensitive   = true
}

variable "cluster_payload_path" {
  type        = string
  description = "Absolute path to the JSON file defining the Kafka cluster"
}

variable "kafka_bootstrap_host" {
  type        = string
  description = "The Kafka bootstrap server hostname and port (e.g., kafka.corp.internal:9093)"
}

variable "kafka_ca_cert" {
  type        = string
  description = "The public CA certificate for the Kafka cluster (PEM format)"
  sensitive   = true
}

variable "kafka_client_cert" {
  type        = string
  description = "The mTLS client certificate (PEM format)"
  sensitive   = true
}

variable "kafka_client_key" {
  type        = string
  description = "The mTLS client private key (PEM format)"
  sensitive   = true
}

variable "cluster_template_path" {
  type        = string
  description = "Absolute or relative path to the cluster JSON template file (.tftpl)"
}