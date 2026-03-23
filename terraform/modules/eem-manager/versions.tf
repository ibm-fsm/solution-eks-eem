terraform {
  # Ensures compatibility with modern Terraform features
  required_version = ">= 1.3.0"

  required_providers {
    # Used for native K8s objects (Namespaces, standard Secrets, ServiceAccounts)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }

    # Used for managing standard Helm charts natively
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }

    # The Gavin Bunney provider is an enterprise standard for applying raw YAML 
    # Custom Resources (like your EventEndpointManagement instance) that the 
    # official hashicorp/kubernetes provider struggles with.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}