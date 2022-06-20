module "waf" {
  source                     = "../../../modules/waf"
  region                     = var.region
  alb_arn                    = var.alb_arn
  enl_master_waf_identifier  = var.enl_master_waf_identifier
}
