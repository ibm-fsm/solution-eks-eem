module "us_equities_data_product" {
  source = "../../modules/eem-data-product"

  # Connection Details (Targeting the Admin API)
  eem_api_url  = var.eem_api_url
  access_token = var.eem_access_token

  cluster_id = var.cluster_id
  data_products_dir = var.data_products_dir
}