locals {
  # jsonencode safely handles all the multi-line certificate escaping automatically
  rendered_cluster_json = jsonencode({
    name = "Core Transactions (Strimzi EKS)"
    bootstrapServers = [
      {
        host = var.kafka_bootstrap_host
        port = 9093
        ssl  = true
        certificates = [
          {
            pem = var.kafka_ca_cert
          }
        ]
      }
    ]
    credentials = {
      type = "MTLS"
      data = {
        clientCertificateAndKey = {
          pem = var.kafka_client_cert
          key = var.kafka_client_key
        }
      }
    }
  })
  
  rendered_file_path = "${path.root}/.rendered-cluster.json"
}

# Save the rendered JSON to a temporary file for the script to use
resource "local_file" "rendered_cluster_payload" {
  content  = local.rendered_cluster_json
  filename = local.rendered_file_path
}

resource "null_resource" "register_kafka_cluster" {
  
  # This hash tells Terraform to re-run the script if you modify the cluster JSON 
  # or add/remove/edit any of the topic JSON files.
  triggers = {
    cluster_hash = md5(local.rendered_cluster_json)
    topics_hash  = sha256(join("", [for f in fileset(var.topic_payload_dir, "*.json") : filemd5("${var.topic_payload_dir}/${f}")]))
  }

  depends_on = [local_file.rendered_cluster_payload]

  provisioner "local-exec" {
    command = "${path.module}/scripts/register-cluster.sh > ${path.root}/kafka-registration.log 2>&1"
    
    # We pass the required data to the script via environment variables
    environment = {
      EEM_API_URL          = var.eem_api_url
      ACCESS_TOKEN         = var.access_token
      CLUSTER_PAYLOAD_PATH = local.rendered_file_path
      TOPIC_PAYLOAD_DIR    = var.topic_payload_dir
    }
  }
}