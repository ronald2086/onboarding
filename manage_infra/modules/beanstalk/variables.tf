variable "service" {
  type        = string
  description = "service resources belongs to"
}

variable "region" {
  type        = string
  description = "The AWS region resource is being deployed to"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "owner" {
  type        = string
  description = "Email distribution list for team responsible for developing and maintaining service​"
}

variable "default_map_server_id" {
  type        = string
  description = "Default server id, Tag for GCP to AWS migration"
}

variable "environment_stack_name" {
  type        = string
  description = "Manage Application Runtime O/S and Server Stack Name"
}

variable "manage_application_files_path" {
  type        = string
  description = "Manage Application Files Path"
}

variable "tenant_instance_timezone" {
  type        = string
  description = "Manage Application Customer/Tenant Timezone"
}

variable "tomcat_jvm_parameters" {
  type        = string
  description = "Manage Application Tomcat Server JVM Options"
}

variable "vpc_id" {
  type        = string
  description = "Manage Application VPC"
}

variable "elb_public_subnets" {
  type        = list
  description = "VPC ELB Subnet Ids"
}

variable "private_subnets" {
  type        = list
  description = "Private subnets where ec2 will be created"
}

variable "instance_type" {
  type        = string
  description = "Information about EC2 instance type, Ex: t2.large"
}

variable "ebs_root_volume_size_in_gb" {
  type        = string
  description = "Manage Application Block Storage Volume Size in GBs"
}

variable "application_port" {
  type        = string
  description = "Manage Application Tomcat Running Port"
}

variable "domain_certificate_arn" {
  type        = string
  description = "The SSL Certificate ARN"
}

variable "manage_database_username" {
  type        = string
  description = "The manage application database username"
}

variable "manage_database_endpoint" {
  type        = string
  description = "The manage application database rds endpoint"
}

variable "manage_database_password" {
  type        = string
  description = "The manage application database password"
}

variable "manage_application_bundle" {
  type        = string
  description = "The Manage application deplyment bundle path"
}

variable "site_con_manage_consumer_cert_ssm" {
  type        = string
  description = "Manage application consumer certificate (to connect to site connectivity) stored in secrets manager"
}

variable "site_con_manage_consumer_cert_key_ssm" {
  type        = string
  description = "Manage application consumer certificate key (to connect to site connectivity) stored in secrets manager"
}

variable "enable_stream_logs" {
  type        = bool
  default     = false
  description = "Whether to create groups in CloudWatch Logs for proxy and deployment logs, and stream logs from each instance in your environment"
}

variable "logs_delete_on_terminate" {
  type        = bool
  default     = false
  description = "Whether to delete the log groups when the environment is terminated. If false, the logs are kept RetentionInDays days"
}

variable "logs_retention_in_days" {
  type        = number
  default     = 7
  description = "The number of days to keep log events before they expire."
}

variable "enable_log_forwarding" {
  type        = bool
  description = "set true to foward EBS platform logs to DataDog."
}

variable "log_shipping_details" {
  type        = object({ destination_arn = string, role_arn = string })
  description = "The log shipping details to ship logs to DataDog"
}

variable "manage_uuid" {
  type        = string
  description = "Unique Manage UUID"
}

variable "iot_core_endpoint" {
  type        = string
  description = "IOT Core Endpoint of Site Connectivity AWS account"
}

variable "private_key_file" {
  type        = string
  description = "The file path of manage cert related private key"
}

variable "private_cert_file" {
  type        = string
  description = "The file path of manage ssl certificate"
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

variable "enable_alb_access_logs" {
  type        = bool
  description = "Enable ALB access logs"
  default     = false
}
