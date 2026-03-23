# ------------------------------------------------------------------------
# Kubernetes & Environment Setup
# ------------------------------------------------------------------------

variable "kube_context" {
  type        = string
  description = "The GitLab agent or local kube context to use"
  default     = "doormat18-group/doormat18-project:eem-eks-agent"
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace for the EEM deployment"
  default     = "ibm-eem"
}

# ------------------------------------------------------------------------
# Container Registry (IBM Entitled Registry)
# ------------------------------------------------------------------------

variable "registry_server" {
  type        = string
  description = "The container registry server"
  default     = "cp.icr.io"
}

variable "registry_user" {
  type        = string
  description = "The username for the container registry"
  default     = "cp"
}

variable "registry_password" {
  type        = string
  description = "The password or entitlement key for the container registry"
  sensitive   = true
}

# ------------------------------------------------------------------------
# Helm Repository Configuration
# ------------------------------------------------------------------------

variable "helm_repo_name" {
  type        = string
  description = "Name of the IBM Helm repository"
  default     = "ibm-helm"
}

variable "helm_repo_url" {
  type        = string
  description = "URL of the IBM Helm repository"
  default     = "https://raw.githubusercontent.com/IBM/charts/master/repo/ibm-helm"
}

variable "crd_chart_name" {
  type        = string
  description = "Name of the IBM EEM Operator CRD Helm chart"
  default     = "ibm-eem-operator-crd"
}

variable "crd_chart_version" {
  type        = string
  description = "Version of the CRD Helm chart"
  default     = "11.7.1"
}

variable "operator_chart_name" {
  type        = string
  description = "Name of the IBM EEM Operator Helm chart"
  default     = "ibm-eem-operator"
}

variable "operator_chart_version" {
  type        = string
  description = "Version of the Operator Helm chart"
  default     = "11.7.1"
}

# ------------------------------------------------------------------------
# Ingress & AWS ALB Routing
# ------------------------------------------------------------------------

variable "ui_hostname" {
  type        = string
  description = "Hostname for the EEM UI"
  default     = "eem-ui-test.local.test"
}

variable "admin_hostname" {
  type        = string
  description = "Hostname for the EEM Admin API"
  default     = "eem-admin-test.local.test"
}

variable "gateway_hostname" {
  type        = string
  description = "Hostname for the EEM Gateway sync"
  default     = "eem-gateway-test.local.test"
}

variable "server_hostname" {
  type        = string
  description = "Hostname for the EEM Server"
  default     = "eem.eem-server-test.local.test"
}

variable "ingress_class" {
  type        = string
  description = "The ingress class to use"
  default     = "alb"
}

variable "alb_scheme" {
  type        = string
  description = "The scheme for the AWS ALB (internet-facing or internal)"
  default     = "internet-facing"
}

variable "alb_group_name" {
  type        = string
  description = "The group name to bind multiple ingresses to a single ALB"
  default     = "eem-manager-test"
}

variable "acm_arn" {
  type        = string
  description = "The AWS ACM Certificate ARN to attach to the ALB"
  sensitive   = true
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file for local-exec commands"
  default     = "~/.kube/config"
}