variable "eem_api_url" {
  type        = string
  description = "The EEM Admin API URL (e.g., https://eem-admin-demo.local.test)"
}

variable "eem_access_token" {
  type        = string
  description = "The token to authenticate with the EEM Admin API"
}

variable "cluster_id" {
  type        = string
  description = "The generated ID of the Kafka Cluster (output from the eem-kafka-registration module)"
}

variable "data_products_dir" {
  type        = string
  description = "Absolute path to the root directory containing the data product folders (e.g., /path/to/data-products/)"
}