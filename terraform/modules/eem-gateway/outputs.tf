output "deployment_name" {
  description = "The name of the Kubernetes Deployment managing the Gateway pods."
  value       = kubernetes_deployment_v1.gateway.metadata[0].name
}

output "tls_secret_name" {
  description = "The name of the Kubernetes Secret containing the cert-manager generated certificates."
  value       = "${var.gateway_group}-${var.gateway_id}-ibm-egw-cert"
}

output "broker_hostnames" {
  description = "The dynamically generated AWS NLB hostnames for the Gateway brokers."
  value = length(var.custom_hostnames) > 0 ? var.custom_hostnames : [
    for svc in kubernetes_service_v1.broker_nlb : svc.status[0].load_balancer[0].ingress[0].hostname
  ]
}