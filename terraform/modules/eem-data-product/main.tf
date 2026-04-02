resource "null_resource" "register_data_products" {
  
  # The trigger recalculates the hash if ANY file in the entire directory tree changes.
  # We use "**/*" to search recursively through all topic and options subfolders.
  triggers = {
    payload_hash = sha256(join("", [
      for f in fileset(var.data_products_dir, "**/*") : 
      filesha256("${var.data_products_dir}/${f}") 
      if can(regex(".*\\.(json|tpl)$", f))
    ]))
    
    # Also trigger if the core cluster changes, ensuring topics are bound to the new cluster
    cluster_id = var.cluster_id
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/register-data-product.sh > ${path.root}/data-product-registration.log 2>&1"
    
    # Pass all required context to the bash script via environment variables
    environment = {
      EEM_API_URL       = var.eem_api_url
      ACCESS_TOKEN      = var.access_token
      CLUSTER_ID        = var.cluster_id
      DATA_PRODUCTS_DIR = var.data_products_dir
    }
  }
}