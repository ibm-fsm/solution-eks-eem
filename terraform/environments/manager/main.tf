# ========================================================================
# Provider Configuration
# ========================================================================

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

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

provider "kubectl" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

# ========================================================================
# EEM Manager Deployment (Test Environment)
# ========================================================================

module "eem_manager" {
  # Point this to the blueprint we just built
  source = "../../modules/eem-manager"

  # ----------------------------------------------------------------------
  # Environment Overrides
  # Note: We don't need to pass variables like ingress_class or helm_repo
  # because the module's variables.tf already has the correct defaults!
  # ----------------------------------------------------------------------

  kube_context = var.kube_context
  kubeconfig_path = var.kubeconfig_path
  namespace    = "ibm-eem-demo"

  # Pass the sensitive variables down from the pipeline
  registry_password = var.registry_password
  acm_arn           = var.acm_arn

  # The clean, flattened hostnames we established for the test cert
  ui_hostname      = "eem-ui-demo.local.test"
  admin_hostname   = "eem-admin-demo.local.test"
  gateway_hostname = "eem-gateway-demo.local.test"
  server_hostname  = "eem.eem-server-demo.local.test"
  
  alb_group_name   = "eem-manager-demo"
}