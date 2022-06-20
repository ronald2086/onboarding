module pagerduty {

  source                = "../../../modules/pagerduty"
  service               = var.service
  region                = var.region
  environment           = var.environment
  owner                 = var.owner
  default_map_server_id = var.default_map_server_id
  pagerduty_endpoint    = var.pagerduty_endpoint

}