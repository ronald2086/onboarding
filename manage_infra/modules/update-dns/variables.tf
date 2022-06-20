variable "service" {
  description = "Service resources belong to"
  type        = string
}

variable "region" {
  type        = string
  description = "The AWS region resource is being deployed to"
}

variable "owner" {
  description = "Team or individual who own this module"
  type        = string
}

variable "environment" {
  description = "Name of environment where resources will be created e.g. dev, test, preprod, prod, common"
  type        = string
}

variable "root_domain" {
  description = "Top level Enlighted domain"
  type        = string
}

variable "manage_domain" {
  description = "Domain for the manage instance"
  type        = string
}

variable "endpoint_url" {
  description = "The URL to the Load Balancer for this Environment"
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
