variable "service" {
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

variable "manage_uuid" {
  type        = string
  description = "Unique Manage UUID"
}

variable "tenant_instance" {
  description = "Tenannt Instance Name"
  type        = string
}

variable "network_account_number" {
  type        = string
  description = "AWS account number where PCA is hosted"
}

variable "pca_arn" {
  type        = string
  description = "ARN of the Private Certificate Authority"
}
