module "update-dns" {
  source                 = "../../../modules/update-dns"
  service                = var.service
  region                 = var.region
  environment            = var.environment
  owner                  = var.owner
  root_domain            = var.root_domain
  manage_domain          = var.manage_domain
  endpoint_url           = var.endpoint_url
  default_map_server_id  = var.default_map_server_id
  network_account_number = var.network_account_number
}
