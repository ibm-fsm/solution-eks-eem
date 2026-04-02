output "registration_complete_id" {
  description = "The ID of the null_resource. Useful for setting depends_on in downstream modules."
  value       = null_resource.register_data_products.id
}