variable "service" {
  description = "service resources belong to"
  type        = string
}

variable "region" {
  description = "The AWS region that you're deploying this resource to"
  type        = string
}

variable "environment" {
  description = "Name of environment where  resources will be created"
  type        = string
}

variable "owner" {
  description = "Email distribution list for team responsible for developing and maintaining service​"
  type        = string
}

variable "datadog_api_key" {
  description = "DataDog API Key for the HTTP endpoint configuration"
  type        = string
  default     = ""
}
