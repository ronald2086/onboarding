module "pca-cert" {
  source                 = "../../../modules/pca-cert"
  service                = var.service
  region                 = var.region
  environment            = var.environment
  owner                  = var.owner
  default_map_server_id  = var.default_map_server_id
  network_account_number = var.network_account_number
  manage_uuid            = var.manage_uuid
  tenant_instance        = var.tenant_instance
  pca_arn                = var.pca_arn
}
