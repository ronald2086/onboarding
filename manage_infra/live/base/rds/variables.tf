variable "service" {
  type        = string
  description = "service resources belong to"
}

variable "region" {
  type        = string
  description = "The AWS region that you're deploying this RDS to"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "owner" {
  type        = string
  description = "Email distribution list for team responsible for developing and maintaining service​"
}

#VPC dependencies
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "A list of CIDR blocks which are allowed to access the database"
}
variable "database_subnets" {
  type        = list(string)
  description = "A list (at least 2) subnets to use for database ips"
}

variable "tenant_rds_snapshot_identifier" {
  type        = string
  default     = ""
  description = "Create RDS instance from snapshot."
}

variable "vpc_id" {
  type        = string
  description = "The vpc id of manage application"
}

variable "dr_region" {
  type        = string
  description = "The AWS region that deploying RDS in case of DR"
}

variable "db_instance_type" {
  type        = string
  description = "The RDS instance type"
}

variable "db_replica_count" {
  type        = number
  description = "The number of db read replicas"
}

variable "rds_map_server_id" {
  type        = string
  description = "RDS server id, Tag for GCP to AWS migration"
}

variable "enable_log_forwarding" {
  type        = bool
  default     = true
  description = "Enables RDS log forwarding to Splunk"
}

variable "manage_database_name" {
  type        = string
  description = "The manage application password"
}

variable "log_destination_name" {
  description = "Log destination name for forwarding logs to Splunk. Optional, if not provided module will generate one from region/env/service name combination"
  type        = string
}

variable "tenant_instance_timezone" {
  type        = string
  description = "Manage Application Customer Timezone"
}