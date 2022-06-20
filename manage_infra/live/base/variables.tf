variable "environment" {
  type        = string
  description = "the AWS environment to deploy to"
}

variable "region" {
  type        = string
  description = "the aws region"
}

variable "dr_region" {
  type        = string
  description = "the disaster recovery region"
}

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
  default     = "Xmx=3g,JVM Options=,Xms=512m"
}

variable "instance_type" {
  type        = string
  description = "Beanstalk EC2 instance types ex:t2.large"
  default     = "t2.medium"
}

variable "application_port" {
  type        = string
  description = "Application port where it is listening"
  default     = "80"
}

variable "ebs_root_volume_size_in_gb" {
  type        = string
  description = "Block Storage Volume Size which will attach to EC2 instance"
  default     = "50"
}

variable "rds_map_server_id" {
  description = "RDS server id, Tag for GCP to AWS migration"
  type        = string
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

variable "fargate_cidr" {
  type        = string
  description = "The VPC Cidr range of the farsgate instances"
}

variable "network_account_number" {
  description = "AWS Account Number for Shared Network Account"
  type        = string
  default     = "226179108462"
}

variable "tenant_rds_snapshot_identifier" {
  type        = string
  default     = ""
  description = "Create RDS instance from snapshot."
}

variable "manage_database_name" {
  type        = string
  description = "The manage application database name ex: ems"
}

variable "manage_database_username" {
  type        = string
  description = "The manage application username"
}

variable "manage_application_bundle" {
  type        = string
  description = "The Manage application deployment zip file path"
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
}

variable "enable_alert_alarms" {
  type        = bool
  description = "To enable pagerduty alarms for Manage application"
  default     = false
}

variable "log_destination_name" {
  description = "The splunk log destination name"
  type        = string
  default     = ""
}

variable "iot_core_endpoint" {
  type        = string
  description = "IOT Core Endpoint of Site Connectivity AWS account"
}

variable "db_replica_count" {
  type        = number
  description = "The manage rds replica count"
  default     = 1
}

variable "pagerduty_endpoint" {
  type        = string
  description = "The Pagerduty endpoint url"
  default     = ""
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog integration api key"
  default     = ""
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog integration app key"
  default     = ""
}

variable "enable_port_80_http_redirect" {
  type        = bool
  description = "To enable port(80) and Manage app redirect from http to https"
  default     = false
}

variable "feature_flag_use_republished_topics" {
  type        = bool
  description = "To enable feature to use republished topics. Refactoring required to define a standard way to set and retrieve feature flags"
}

variable "manage_uuid" {
  type        = string
  description = "The unique identifier to identify a manage instance. Comes from tenant config"

  validation {
    # Validate if it is in correct UUID format
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.manage_uuid))
    error_message = "The manage UUID must be a valid UUID."
  }
}