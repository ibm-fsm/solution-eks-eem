variable "namespace" {
  type        = string
  description = "The namespace where the gateway will be deployed."
}

variable "gateway_group" {
  type        = string
  description = "The logical group name for the gateway."
}

variable "gateway_id" {
  type        = string
  description = "The unique identifier for the gateway."
}

variable "broker_count" {
  type        = number
  description = "The number of broker LoadBalancer services to create."
  default     = 3
}

variable "custom_hostnames" {
  type        = list(string)
  description = "Optional list of predefined Route 53 hostnames. If left empty, AWS generated hostnames will be output."
  default     = []
}

variable "backend_url" {
  type        = string
  description = "The gateway endpoint on the EEM Manager (e.g., https://eem-gateway.<dns>). The Gateway pod uses this Control Plane URL to authenticate and fetch its configuration."
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to the Kubernetes config file."
  default = "~/.kube/config"
}

variable "kube_context" {
  type        = string
  description = "Kubernetes context to use."
}