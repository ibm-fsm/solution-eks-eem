# ------------------------------------------------------------------------
# Environment Information
# ------------------------------------------------------------------------

output "namespace" {
  description = "The Kubernetes namespace where the EEM Manager was deployed."
  value       = var.namespace
}

output "alb_group_name" {
  description = "The AWS ALB group name managing the ingress traffic."
  value       = var.alb_group_name
}

# ------------------------------------------------------------------------
# Connection Endpoints
# ------------------------------------------------------------------------

output "ui_url" {
  description = "The HTTPS endpoint for the Event Endpoint Management UI."
  value       = "https://${var.ui_hostname}"
}

output "admin_api_url" {
  description = "The HTTPS endpoint for the EEM Admin API."
  value       = "https://${var.admin_hostname}"
}

output "gateway_sync_url" {
  description = "The HTTPS endpoint used by remote Gateways to sync with this Manager."
  value       = "https://${var.gateway_hostname}:7001"
}

output "server_url" {
  description = "The HTTPS endpoint for the internal EEM Server components."
  value       = "https://${var.server_hostname}"
}

# ------------------------------------------------------------------------
# OIDC / SSO Configuration Requirements
# ------------------------------------------------------------------------

output "oidc_redirect_uris" {
  description = "The callback URLs that must be whitelisted in the identity provider (e.g., IBM Verify / Entra ID)."
  value = {
    login_callback  = "https://${var.ui_hostname}/callback"
    logout_callback = "https://${var.ui_hostname}/logout/callback"
  }
}