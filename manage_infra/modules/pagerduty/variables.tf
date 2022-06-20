variable "service" {
  type        = string
  description = "service resources belong to"
}

variable "region" {
  type        = string
  description = "The AWS region that you're deploying this pagerduty"
}

variable "environment" {
  type        = string
  description = "Name of environment where  resources will be created"
}

variable "owner" {
  type        = string
  description = "Email distribution list for team responsible for developing and maintaining service​"
}

variable "pagerduty_endpoint" {
  type        = string
  description = "The pagerduty endpoint."
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

