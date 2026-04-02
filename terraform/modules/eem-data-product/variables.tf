variable "eem_api_url" {
  type        = string
  description = "The Admin URL of the EEM Manager (e.g., https://eem.eem-server-test.local.test/admin)"
}

variable "access_token" {
  type        = string
  description = "The Bearer token for EEM API authentication"
  sensitive   = true
}

variable "cluster_id" {
  type        = string
  description = "The generated ID of the Kafka Cluster (output from the eem-kafka-registration module)"
}

variable "data_products_dir" {
  type        = string
  description = "Absolute path to the root directory containing the data product folders (e.g., /path/to/data-products/)"
}