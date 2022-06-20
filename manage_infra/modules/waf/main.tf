locals {
  region                     = var.region
  enl-waf-core-rule-set      = "enl-waf-core-rule-set"
  enl_master_waf_identifier  = var.enl_master_waf_identifier
  app_load_arn               = var.alb_arn
}


data "aws_wafv2_web_acl" "enl_org_web_acl" {
  name  = "FMManagedWebACLV2${local.enl-waf-core-rule-set}-${local.region}${local.enl_master_waf_identifier}"
  scope = "REGIONAL"
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = data.aws_wafv2_web_acl.enl_org_web_acl.arn
}