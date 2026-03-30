output "broker_hostnames" {
  description = "The final list of hostnames to be used by the Gateway and cert-manager."
  value = length(var.custom_hostnames) > 0 ? var.custom_hostnames : [
    for svc in kubernetes_service_v1.broker_nlb : svc.status[0].load_balancer[0].ingress[0].hostname
  ]
}