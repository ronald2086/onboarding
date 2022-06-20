variable "service" {
  description = "service resources belong to"
}

variable "region" {
  type        = string
  description = "The AWS region that you're deploying this module to"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "owner" {
  description = "Email distribution list for team responsible for developing and maintaining service"
  type        = string
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

variable "network_account_number" {
  description = "AWS Account Number for Shared Network Account"
  type        = string
}

variable "manage_uuid" {
  type        = string
  description = "Unique Manage UUID"
}

variable "tenant_instance" {
  description = "Tenannt Instance Name"
  type        = string
}

variable "pca_arn" {
  type        = string
  description = "ARN of the Private Certificate Authority"
}
