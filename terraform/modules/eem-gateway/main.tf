resource "kubernetes_service_v1" "broker_nlb" {
  count = var.broker_count

  metadata {
    name      = "${var.gateway_group}-${var.gateway_id}-broker-${count.index}"
    namespace = var.namespace
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"                 = "nlb-ip"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"      = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "TCP"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"               = "internet-facing"
    }
  }

  spec {
    type             = "LoadBalancer"
    session_affinity = "None"

    selector = {
      app          = "${var.gateway_group}-${var.gateway_id}"
      gatewayGroup = var.gateway_group
      gatewayId    = var.gateway_id
    }

    port {
      name        = "broker-${count.index}"
      protocol    = "TCP"
      port        = 443
      target_port = 8443
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].load_balancer_class,
      # It's best practice to ignore annotations, as AWS LBC 
      # often injects target-group ARNs here dynamically later on.
      metadata[0].annotations
    ]
  }  
}