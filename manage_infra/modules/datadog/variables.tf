variable "region" {
  type        = string
  description = "The AWS region that you're deploying this datadog dashboard"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "service" {
  type        = string
  description = "The name of the manage application tenanat name"
}

variable "rds_cluster_resource_id" {
  type        = string
  description = "The db cluster identifier"
}

variable "enable_dd_dashboard" {
  type        = bool
  description = "To enable datadog dashboard"
  default     = false
}
variable "datadog_api_key" {
  type        = string
  description = "Datadog API key. This can also be set via the DD_API_KEY environment variable"
  default     = ""
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog APP key. This can also be set via the DD_APP_KEY environment variable"
  default     = ""
}

variable "beanstalk_environment_name" {
  type        = string
  description = "Manage application beanstalk environment name"
}