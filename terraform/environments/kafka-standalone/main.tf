module "kafka_registration" {
    source = "../../modules/eem-kafka-registration"

    eem_api_url          = var.eem_api_url
    access_token         = "9eb0cf83-fec2-45bd-8c02-05c1cc61402d"
    cluster_payload_path = "../test/kafka-payloads/rendered-cluster.json"
    topic_payload_dir    = "../test/kafka-payloads/"
    kafka_bootstrap_host = var.kafka_bootstrap_host
    kafka_ca_cert        = var.kafka_ca_cert
    kafka_client_cert    = var.kafka_client_cert
    kafka_client_key     = var.kafka_client_key
    cluster_template_path = "../test/kafka-payloads/eem-01-cluster.json.tftpl"
}