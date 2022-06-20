locals {
  service     = format("%s-%s", var.tenant_instance_name, "manage")
  environment = var.environment
  region      = var.region
  owner       = format("dsp-%s-service@enlightedinc.com", local.service)
  account_id  = data.aws_caller_identity.current.account_id
  roles = [
    "arn:aws:iam::${local.account_id}:role/Deployer",
    "arn:aws:iam::${local.account_id}:role/Administrator",
    "arn:aws:iam::${local.account_id}:role/Developer"
  ]
}

provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

module "s3" {
  source                = "../../../modules/s3-bootstrap"
  environment           = local.environment
  region                = local.region
  service               = local.service
  owner                 = local.owner
  access_roles          = local.roles
  default_map_server_id = var.default_map_server_id
}