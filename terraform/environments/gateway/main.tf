terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

module "eem_manager" {
    source = "../../modules/eem-gateway"
    namespace = var.namespace
    gateway_group = var.gateway_group
    gateway_id = var.gateway_id
    backend_url = var.backend_url
}

output "gateway_broker_hostnames" {
  description = "The AWS NLB hostnames for the Gateway brokers."
  value       = module.eem_manager.broker_hostnames
}

output "gateway_deployment_name" {
  description = "The name of the Kubernetes Deployment managing the Gateway pods."
  value       = module.eem_manager.deployment_name
}

output "gateway_tls_secret_name" {
  description = "The name of the Kubernetes Secret containing the cert-manager generated certificates."
  value       = module.eem_manager.tls_secret_name
}
