locals {
  # Comes from tenant config
  manage_uuid = var.manage_uuid

  service     = format("%s-%s", var.tenant_instance_name, "manage")
  region      = var.region
  dr_region   = var.dr_region
  environment = var.environment
  owner       = "dsp-manage-support@enlightedinc.com"

  root_domain   = "manage.enlightedinc.com"
  manage_domain = local.environment == "prod" ? "${local.service}.${local.root_domain}" : "${local.service}-${local.environment}-${local.region}.${local.root_domain}"

  # database variables
  rds_map_server_id        = var.rds_map_server_id
  default_map_server_id    = var.default_map_server_id
  db_replica_count         = var.db_replica_count
  db_instance_type         = var.db_instance_type
  fargate_cidr             = var.fargate_cidr
  manage_database_name     = var.manage_database_name
  manage_database_username = var.manage_database_username

  # beanstalk variables
  tenant_instance_timezone            = var.tenant_instance_timezone
  environment_stack_name              = var.environment_stack_name
  manage_application_files_path       = var.manage_artifacts_path
  tomcat_jvm_parameters               = var.tomcat_jvm_parameters
  associate_public_ip_address         = var.associate_public_ip_address
  instance_type                       = var.instance_type
  ebs_root_volume_size_in_gb          = var.ebs_root_volume_size_in_gb
  application_port                    = var.application_port
  network_account_number              = var.network_account_number
  iot_core_endpoint                   = var.iot_core_endpoint
  feature_flag_use_republished_topics = var.feature_flag_use_republished_topics

  # Replace actual Manage application zip file below.
  manage_application_bundle = var.manage_application_bundle == "" ? "../../live/playground/manage-draft-app-bundle-2021.zip" : var.manage_application_bundle

  #private certifictae authority ARN in Network account
  pca_arn = var.pca_arn
  #ORG Security Identifier - Unique for each AWS account.
  enl_master_waf_identifier = var.enl_master_waf_identifier

  # Logs
  enable_vpc_flowlogs          = local.environment == "prod" ? true : false
  enable_ebs_stream_logs       = true
  ebs_logs_delete_on_terminate = local.environment == "prod" ? false : true
  ebs_logs_retention_in_days   = 7

  # DataDog Logs
  enable_datadog_log_forwarding = true
  log_shipping_details          = local.enable_datadog_log_forwarding ? module.log_shipper[0].log_shipping_details : null

  # Splunk Logs (only for RDS)
  enable_rds_splunk_log_forwarding = true
  log_destination_name             = var.log_destination_name != "" ? var.log_destination_name : "enl-${local.environment}-manage"

  enable_alert_alarms = var.enable_alert_alarms
  pagerduty_endpoint  = var.pagerduty_endpoint != "" ? var.pagerduty_endpoint : "https://events.pagerduty.com/integration/1e14bc1c7eb44108d097e70d60918918/enqueue"
}

provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

#The resource is not used. Exists only to avoid cycle error in terraform. Should be removed once all existing deployments are redeployed once.
resource "random_uuid" "manage_uuid" {
}

module "log_shipper" {
  source = "../../modules/log-shipper"
  count  = local.enable_datadog_log_forwarding ? 1 : 0

  service     = local.service
  environment = local.environment
  region      = local.region
  owner       = local.owner

  datadog_api_key = var.datadog_api_key
}

module "vpc" {
  source      = "./vpc"
  service     = local.service
  region      = local.region
  environment = local.environment
  owner       = local.owner
  cidr        = var.cidr
  azs = [
    "us-east-1a",
    "us-east-1b"
  ]
  private_subnets       = var.private_subnets
  database_subnets      = var.database_subnets
  enable_ssm_endpoints  = false
  tag_aws_map_server_id = local.default_map_server_id
  public_subnets        = var.public_subnets

  enable_vpc_flowlogs  = local.enable_vpc_flowlogs && local.enable_datadog_log_forwarding
  log_shipping_details = local.log_shipping_details
}

module "rds" {
  source                   = "./rds"
  service                  = local.service
  region                   = local.region
  environment              = local.environment
  owner                    = local.owner
  dr_region                = local.dr_region
  rds_map_server_id        = local.rds_map_server_id
  allowed_cidr_blocks      = [local.fargate_cidr]
  tenant_instance_timezone = local.tenant_instance_timezone

  #vpc dependencies
  vpc_id                = module.vpc.vpc_id
  database_subnets      = module.vpc.vpc_database_subnets
  db_instance_type      = local.db_instance_type
  db_replica_count      = local.db_replica_count
  manage_database_name  = local.manage_database_name
  enable_log_forwarding = local.enable_rds_splunk_log_forwarding
  log_destination_name  = local.log_destination_name
}

module "create-domain-cert" {
  source                 = "./create-domain-cert"
  service                = local.service
  region                 = local.region
  environment            = local.environment
  owner                  = local.owner
  root_domain            = local.root_domain
  manage_domain          = local.manage_domain
  default_map_server_id  = local.default_map_server_id
  network_account_number = local.network_account_number
}

module "pca-cert" {
  source                 = "../base/pca-cert"
  service                = local.service
  region                 = local.region
  environment            = local.environment
  owner                  = local.owner
  default_map_server_id  = local.default_map_server_id
  manage_uuid            = local.manage_uuid
  network_account_number = local.network_account_number
  tenant_instance        = var.tenant_instance_name
  pca_arn                = local.pca_arn
}

module "manage-beanstalk" {
  source                                = "./beanstalk"
  service                               = local.service
  region                                = local.region
  environment                           = local.environment
  owner                                 = local.owner
  default_map_server_id                 = local.default_map_server_id
  tenant_instance_timezone              = local.tenant_instance_timezone
  environment_stack_name                = local.environment_stack_name
  manage_application_files_path         = local.manage_application_files_path
  tomcat_jvm_parameters                 = local.tomcat_jvm_parameters
  application_port                      = local.application_port
  instance_type                         = local.instance_type
  ebs_root_volume_size_in_gb            = local.ebs_root_volume_size_in_gb
  vpc_id                                = module.vpc.vpc_id
  elb_public_subnets                    = module.vpc.vpc_public_subnets
  private_subnets                       = module.vpc.vpc_private_subnets
  domain_certificate_arn                = module.create-domain-cert.domain_cert_arn
  manage_database_username              = local.manage_database_username
  manage_database_endpoint              = module.rds.cluster_endpoint
  manage_database_password              = module.rds.this_rds_cluster_master_password
  manage_application_bundle             = local.manage_application_bundle
  site_con_manage_consumer_cert_ssm     = module.pca-cert.ssm_private_certficate_name
  site_con_manage_consumer_cert_key_ssm = module.pca-cert.ssm_private_key_name
  manage_uuid                           = local.manage_uuid
  iot_core_endpoint                     = local.iot_core_endpoint
  feature_flag_use_republished_topics   = local.feature_flag_use_republished_topics

  enable_stream_logs       = local.enable_ebs_stream_logs
  logs_delete_on_terminate = local.ebs_logs_delete_on_terminate
  logs_retention_in_days   = local.ebs_logs_retention_in_days
  enable_log_forwarding    = local.enable_datadog_log_forwarding
  log_shipping_details     = local.log_shipping_details

  private_key_file             = module.pca-cert.private_key_file
  private_cert_file            = module.pca-cert.private_cert_file
  enable_port_80_http_redirect = var.enable_port_80_http_redirect

  depends_on = [module.rds.this_rds_cluster_instance_endpoints, module.pca-cert, module.create-domain-cert]
}

module "update-dns" {
  source                 = "./update-dns"
  service                = local.service
  region                 = local.region
  environment            = local.environment
  owner                  = local.owner
  root_domain            = local.root_domain
  manage_domain          = local.manage_domain
  endpoint_url           = module.manage-beanstalk.env_endpoint_url
  default_map_server_id  = local.default_map_server_id
  network_account_number = local.network_account_number
}


module "waf" {
  source                     = "../base/waf"
  region                     = local.region
  alb_arn                    = element(tolist(module.manage-beanstalk.env_load_balancers), 0)
  enl_master_waf_identifier  = local.enl_master_waf_identifier
}

module "pagerduty" {
  source                = "../base/pagerduty"
  service               = local.service
  region                = local.region
  environment           = local.environment
  owner                 = local.owner
  default_map_server_id = local.default_map_server_id
  pagerduty_endpoint    = local.pagerduty_endpoint
}

module "manage_cw_pagerduty_alarms" {
  count                 = local.enable_alert_alarms ? 1 : 0
  source                = "../base/alarms"
  service               = local.service
  region                = local.region
  environment           = local.environment
  default_map_server_id = local.default_map_server_id
  owner                 = local.owner

  auto_scaling_group_name    = module.manage-beanstalk.autoscaling_groups[0]
  pager_duty_sns_topic_arn   = module.pagerduty.pagerduty_sns_topic_arn
  beanstalk_load_balancer    = join("/", slice(split("/", module.manage-beanstalk.load_balancers[0]), 1, 4))
  beanstalk_environment_name = module.manage-beanstalk.beanstalk_environment_name
  beanstalk_env_instance_id  = module.manage-beanstalk.instances[0]
  db_cluster_identifier      = "${local.service}-${local.region}-${local.environment}-rds"

  depends_on = [module.rds.this_rds_cluster_instance_endpoints, module.manage-beanstalk, module.pagerduty]
}


module "dashboards" {
  source                     = "../../modules/datadog"
  enable_dd_dashboard        = (var.datadog_api_key != "" && var.datadog_app_key != "") ? true : false
  datadog_api_key            = var.datadog_api_key
  datadog_app_key            = var.datadog_app_key
  service                    = local.service
  region                     = local.region
  environment                = local.environment
  beanstalk_environment_name = module.manage-beanstalk.beanstalk_environment_name
  rds_cluster_resource_id    = module.rds.cluster_resource_id
}

output "manage_application_accessible_url" {
  description = "The accessible url of manage application"
  value       = format("\n-------------------\n https://%s \n-------------------", local.manage_domain)

  depends_on = [module.update-dns]
}

output "pca_arn" {
  description = "ARN of the Private Certificate Authority"
  value       = local.pca_arn
}

output "iot_consumer_cert_arn" {
  description = "ARN of the IoT consumer certificate"
  value       = module.pca-cert.iot_consumer_cert_arn
}

output "manage_uuid" {
  description = "Manage UUID"
  value       = local.manage_uuid
}
