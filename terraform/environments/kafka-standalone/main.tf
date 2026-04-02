module "kafka_registration" {
    source = "../../modules/eem-kafka-registration"

    eem_api_url          = var.eem_api_url
    access_token         = var.access_token
    cluster_payload_path = var.cluster_payload_path
    kafka_bootstrap_host = var.kafka_bootstrap_host
    kafka_ca_cert        = var.kafka_ca_cert
    kafka_client_cert    = var.kafka_client_cert
    kafka_client_key     = var.kafka_client_key
    cluster_template_path = var.cluster_template_path
}