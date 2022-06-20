variable "environment" {
  type        = string
  description = "the AWS environment to deploy to"
}

variable "region" {
  type        = string
  description = "the aws region"
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

variable "tenant_instance_name" {
  type        = string
  description = "The name of the tenant instance name ex: saleforce2"
}