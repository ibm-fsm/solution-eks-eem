variable "kube_context" {
  type        = string
  description = "The GitLab agent kube context"
  default     = "doormat18-group/doormat18-project:eem-eks-agent"
}

variable "registry_password" {
  type        = string
  description = "IBM Entitlement Key"
  sensitive   = true
}

variable "acm_arn" {
  type        = string
  description = "The AWS ACM Certificate ARN"
  sensitive   = true
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file"
  default     = "~/.kube/config"
}