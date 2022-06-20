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

variable "auto_scaling_group_name" {
  type        = string
  description = "The manage beanstalk environment asg"
}

variable "pager_duty_sns_topic_arn" {
  type        = string
  description = "Pagerduty alarm target topic arn"
}

variable "beanstalk_load_balancer" {
  type        = string
  description = "Manage application beanstalk environment load balancer"
}

variable "beanstalk_env_instance_id" {
  type        = string
  description = "Manage application beanstalk ec2 instance id"
}

variable "beanstalk_environment_name" {
  type        = string
  description = "Manage application beanstalk environment name"
}

variable "db_cluster_identifier" {
  type        = string
  description = "Manage application database cluster identifier"
}

variable "default_map_server_id" {
  type        = string
  description = "Default server id, Tag for GCP to AWS migration"
}

variable "owner" {
  type        = string
  description = "Email distribution list for team responsible for developing and maintaining service​"
}