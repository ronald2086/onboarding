variable "region" {
  type        = string
  description = "The AWS region resource is being deployed to"
}

variable "enl_master_waf_identifier" {
  description = "Timestamp of the org Web ACL (suffix) in current AWS account. It was generated when security team published org level web acl in master account"
  type        = string
}

variable "alb_arn" {
  description = "ARN for the Manage Application Load Balancer"
  type        = string
}
