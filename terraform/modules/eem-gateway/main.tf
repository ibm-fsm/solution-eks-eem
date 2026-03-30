locals {
  # The base name used across all resources
  base_name = "${var.gateway_group}-${var.gateway_id}"

  # Dynamically generate the internal Kubernetes hostnames per broker
  internal_dns_names = flatten([
    for i in range(var.broker_count) : [
      "${local.base_name}-broker-${i}.${var.namespace}",
      "${local.base_name}-broker-${i}.${var.namespace}.svc",
      "${local.base_name}-broker-${i}.${var.namespace}.svc.cluster.local"
    ]
  ])

  # Grab the external hostnames (either custom ones or the AWS NLB ones)
  external_dns_names = length(var.custom_hostnames) > 0 ? var.custom_hostnames : [
    for svc in kubernetes_service_v1.broker_nlb : svc.status[0].load_balancer[0].ingress[0].hostname
  ]

  # Combine them all into a single list for the Certificate
  all_dns_names = concat(local.internal_dns_names, local.external_dns_names)
}

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

# Create the Issuer pointing to the Manager's CA
resource "kubernetes_manifest" "gateway_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "${local.base_name}-ibm-egw-iss"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/component" = "ibm-egw"
        "app.kubernetes.io/instance"  = local.base_name
        "app.kubernetes.io/name"      = "ibm-event-endpoint-management"
      }
    }
    spec = {
      ca = {
        secretName = "eem-manager-ibm-eem-manager-ca"
      }
    }
  }
}

# Create the Certificate using the dynamic DNS names
resource "kubernetes_manifest" "gateway_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${local.base_name}-ibm-egw-cert"
      namespace = var.namespace
      annotations = {
        productChargedContainers = "manager;egw"
        productID                = "682b6db3fed247a098d85da5ab905b46"
        productMetric            = "VIRTUAL_PROCESSOR_CORE"
        productName              = "IBM Event Automation"
      }
      labels = {
        "app.kubernetes.io/component"  = "ibm-egw"
        "app.kubernetes.io/instance"   = local.base_name
        "app.kubernetes.io/name"       = "ibm-event-endpoint-management"
        "events.ibm.com/component"     = "${local.base_name}-ibm-egw"
      }
    }
    spec = {
      dnsNames   = local.all_dns_names
      duration   = "2160h"
      issuerRef = {
        kind = "Issuer"
        name = kubernetes_manifest.gateway_issuer.manifest.metadata.name
      }
      privateKey = {
        algorithm      = "RSA"
        rotationPolicy = "Always"
      }
      secretName = "${local.base_name}-ibm-egw-cert"
      secretTemplate = {
        annotations = {
          productChargedContainers = "manager;egw"
          productID                = "682b6db3fed247a098d85da5ab905b46"
          productMetric            = "VIRTUAL_PROCESSOR_CORE"
          productName              = "IBM Event Automation"
        }
        labels = {
          "app.kubernetes.io/component"  = "ibm-egw"
          "app.kubernetes.io/instance"   = local.base_name
          "app.kubernetes.io/name"       = "ibm-event-endpoint-management"
          "events.ibm.com/component"     = "${local.base_name}-ibm-egw"
        }
      }
      subject = {
        organizations = ["IBM Event Endpoint Management"]
      }
      usages = [
        "client auth",
        "digital signature",
        "server auth"
      ]
    }
  }
}