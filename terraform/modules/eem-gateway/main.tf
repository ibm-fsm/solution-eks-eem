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

  # Append :443 to each external AWS hostname and join them with commas
  kafka_advertised_listener = join(",", [for host in local.external_dns_names : "${host}:443"])
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

resource "kubernetes_deployment_v1" "gateway" {
  metadata {
    name      = local.base_name
    namespace = var.namespace
    labels = {
      app          = local.base_name
      gatewayGroup = var.gateway_group
      gatewayId    = var.gateway_id
    }
    annotations = {
      productChargedContainers = "manager;egw"
      productID                = "682b6db3fed247a098d85da5ab905b46"
      productMetric            = "VIRTUAL_PROCESSOR_CORE"
      productName              = "IBM Event Automation"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app          = local.base_name
        gatewayGroup = var.gateway_group
        gatewayId    = var.gateway_id
      }
    }

    template {
      metadata {
        labels = {
          app          = local.base_name
          gatewayGroup = var.gateway_group
          gatewayId    = var.gateway_id
        }
        annotations = {
          productChargedContainers = "manager;egw"
          productID                = "682b6db3fed247a098d85da5ab905b46"
          productMetric            = "VIRTUAL_PROCESSOR_CORE"
          productName              = "IBM Event Automation"
        }
      }

      spec {
        container {
          name  = "egw"
          image = "icr.io/cpopen/ibm-eventendpointmanagement/egw@sha256:448ec9e5eed0bb8d6a5fbf3ab1baba5894def6e5937ec19533b3ae46d454a2db"

          resources {
            limits = {
              cpu                 = "2"
              "ephemeral-storage" = "800M"
              memory              = "2Gi"
            }
            requests = {
              cpu                 = "1"
              "ephemeral-storage" = "800M"
              memory              = "1Gi"
            }
          }

          port {
            container_port = 8443
            name           = "kafka-client"
          }

          env {
            name  = "GATEWAY_ID"
            value = var.gateway_id
          }
          env {
            name  = "GATEWAY_GROUP"
            value = var.gateway_group
          }
          env {
            name  = "TLS_VERSIONS"
            value = "TLSv1.2,TLSv1.3"
          }
          env {
            # IMPORTANT: This must be the gateway endpoint on the EEM Manager.
            name  = "backendURL"
            value = var.backend_url
          }
          env {
            name  = "GATEWAY_PORT"
            value = "8443"
          }
          env {
            # Dynamically inserts the AWS NLB hostnames + :443
            name  = "KAFKA_ADVERTISED_LISTENER"
            value = local.kafka_advertised_listener
          }
          env {
            name = "BACKEND_CA_CERTIFICATES"
            value_from {
              secret_key_ref {
                name = "eem-manager-ibm-eem-manager-ca"
                key  = "ca.crt"
              }
            }
          }
          env {
            name  = "LICENSE_ID"
            value = "L-CYBH-K48BZQ"
          }
          env {
            name  = "ACCEPT_LICENSE"
            value = "true"
          }
          env {
            name  = "certPaths"
            value = "/certs/eem/client.pem,/certs/eem/client.key,/certs/eem/egwclient.pem,/certs/eem/egwclient-key.pem,/certs/eem/ca.pem"
          }

          volume_mount {
            name       = "egw-certs"
            mount_path = "/certs/eem"
            read_only  = true
          }
        }

        volume {
          name = "egw-certs"
          secret {
            # Points directly to the Secret cert-manager will generate
            secret_name  = "${local.base_name}-ibm-egw-cert"
            default_mode = "0644"
            
            items {
              key  = "tls.crt"
              path = "client.pem"
            }
            items {
              key  = "tls.key"
              path = "client.key"
            }
            items {
              key  = "tls.crt"
              path = "egwclient.pem"
            }
            items {
              key  = "tls.key"
              path = "egwclient-key.pem"
            }
            items {
              key  = "ca.crt"
              path = "ca.pem"
            }
          }
        }
      }
    }
  }
}