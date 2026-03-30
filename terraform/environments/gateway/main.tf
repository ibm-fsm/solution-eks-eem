module "eem_manager" {
    source = "../../modules/eem-gateway"
    namespace = var.namespace
    gateway_group = var.gateway_group
    gateway_id = var.gateway_id
}

output "gateway_broker_hostnames" {
  description = "The AWS NLB hostnames for the Gateway brokers."
  value       = module.eem_manager.broker_hostnames
}