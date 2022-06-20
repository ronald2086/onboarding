module "create-domain-cert" {
  source                 = "../../../modules/create-domain-cert"
  service                = var.service
  region                 = var.region
  environment            = var.environment
  owner                  = var.owner
  manage_domain          = var.manage_domain
  root_domain            = var.root_domain
  default_map_server_id  = var.default_map_server_id
  network_account_number = var.network_account_number
}
