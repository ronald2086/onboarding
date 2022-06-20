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
  description = "Email distribution list for team responsible for developing and maintaining service​"
  type        = string
}

variable "access_roles" {
  description = "Roles to be allowed access to bucket"
  type        = list(string)
  default     = []
}

variable "default_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}
