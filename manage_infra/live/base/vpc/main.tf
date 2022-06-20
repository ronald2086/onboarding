provider "aws" {
  region = var.region
}

module "vpc" {
  source = "git::ssh://git@bitbucket.org/enlightedinc/terraform-enl-aws-vpc.git?ref=v0.12.4"

  service_name = var.service
  app_name     = var.service
  region       = var.region
  environment  = var.environment
  owner        = var.owner
  tags         = { map-migrated = var.tag_aws_map_server_id }

  cidr                  = var.cidr
  azs                   = var.azs
  private_subnets       = var.private_subnets
  database_subnets      = var.database_subnets
  is_shared_services    = false
  enable_ssm_endpoints  = var.enable_ssm_endpoints
  create_test_instance  = false
  tag_aws_map_server_id = var.tag_aws_map_server_id
  public_subnets        = var.public_subnets

  enable_vpc_flowlogs_dd  = var.enable_vpc_flowlogs
  dd_log_shipping_details = var.log_shipping_details
}
