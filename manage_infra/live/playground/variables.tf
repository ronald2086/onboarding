variable "private_subnets" {
  type        = list(string)
  description = "Configure to your assigned IP range. Contact you developer leads in dsp-cicd."
}

variable "database_subnets" {
  type        = list(string)
  description = "A list of database subnets inside the VPC. Must a subset of your private subnets."
}

variable "cidr" {
  type        = string
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets inside the VPC."
}

variable "network_account_number" {
  type        = string
  default     = "226179108462"
  description = "AWS Account Number for Shared Network Account"
}

variable "db_instance_type" {
  type        = string
  description = "Database machine size ex:db.t3.medium"
  default     = "db.t3.medium"
}

variable "tenant_instance_timezone" {
  type        = string
  description = "Tenant Deployment Time Zone"
  default     = "US/Pacific"
}

variable "environment_stack_name" {
  type        = string
  description = "Tenant Deployment O/S and Server Information"
  default     = "64bit Amazon Linux 2018.03 v3.4.16 running Tomcat 8.5 Java 8"
}

variable "tomcat_jvm_parameters" {
  type        = string
  description = "Tomcat JVM Server Information"
  default     = "Xmx=3g,JVM Options=-Dorg.apache.el.parser.SKIP_IDENTIFIER_CHECK=true,Xms=512m"
}

variable "instance_type" {
  type        = string
  description = "Beanstalk EC2 instance types ex:t2.large"
  default     = "t2.medium"
}

variable "ebs_root_volume_size_in_gb" {
  type        = string
  description = "Block Storage Volume Size which will attach to EC2 instance"
  default     = "50"
}

variable "manage_artifacts_path" {
  type        = string
  description = "The location of manage application dependency files path"
  default     = "/var/lib/tomcat8"
}

variable "associate_public_ip_address" {
  type        = string
  description = "Should associate public ip to load balancer or not"
  default     = "true"
}

variable "application_port" {
  type        = string
  description = "Application port where it is listening"
  default     = "80"
}

variable "manage_application_bundle" {
  type        = string
  description = "The Manage application deployment zip file path"
  default     = ""
}

variable "tenant_instance_name" {
  type        = string
  description = "The name of the tenant instance name ex: saleforce2"
}
variable "pca_arn" {
  type        = string
  description = "ARN of the Private Certificate Authority in Network Account"
  default     = "arn:aws:acm-pca:us-east-1:226179108462:certificate-authority/8196aa88-8942-4cc5-87fe-e8d45b615339"
}

variable "enl_master_waf_identifier" {
  description = "Timestamp of the org Web ACL (suffix) in current AWS account. It was generated when security team published org level web acl in master account"
  type        = string
  default     = "1615842224534"
}
variable "tenant_rds_snapshot_identifier" {
  type        = string
  default     = ""
  description = "Create RDS instance from snapshot."
}

variable "iot_core_endpoint" {
  type        = string
  description = "IOT Core Endpoint of Site Connectivity AWS account"
}

variable "log_destination_name" {
  description = "The splunk log destination name"
  type        = string
  default     = ""
}

variable "manage_database_username" {
  type        = string
  description = "The manage application username"
}

variable "manage_database_name" {
  type        = string
  description = "The manage application password"
}

variable "vpn_cidr" {
  type        = string
  description = "The CIDR range the lambda VPC is configured to use"
}
variable "fargate_cidr" {
  type        = string
  description = "The VPC Cidr range of the farsgate instances"
}

variable "rds_map_server_id" {
  description = "RDS server id, Tag for GCP to AWS migration"
  type        = string
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

variable "region" {
  type        = string
  description = "the aws region"
}

variable "dr_region" {
  type        = string
  description = "the disaster recovery region"
}

variable "db_replica_count" {
  type        = number
  description = "The manage rds replica count"
}

variable "environment" {
  type        = string
  description = "the AWS environment to deploy to"
}

variable "enable_alert_alarms" {
  type        = bool
  description = "To enable pagerduty alarms for Manage application"
  default     = false
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API key. This can also be set via the DD_API_KEY environment variable"
  default     = ""
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog APP key. This can also be set via the DD_APP_KEY environment variable"
  default     = ""
}

variable "enable_port_80_http_redirect" {
  type        = bool
  description = "To enable port(80) and Manage app redirect from http to https"
  default     = false
}