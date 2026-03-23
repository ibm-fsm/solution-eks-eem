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

variable "public_registry_server" {
  type        = string
  description = "The registry server for public EEM images"
  default     = "icr.io" 
}

variable "private_registry_server" {
  type        = string
  description = "The registry server for private/entitled EEM images"
  default     = "cp.icr.io" 
}

variable "public_registry_path" {
  type        = string
  description = "The repository path for the public EEM images"
  default     = "cpopen/" 
}

variable "private_registry_path" {
  type        = string
  description = "The repository path for the private EEM images"
  default     = "cp/ibm-eventendpointmanagement/" 
}