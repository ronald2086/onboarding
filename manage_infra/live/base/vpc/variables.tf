variable "service" {
  description = "service resources belong to"
}

variable "region" {
  type        = string
  description = "The AWS region that you're deploying this VPC to"
}

variable "environment" {
  type        = string
  description = "The environment for the deployed resources"
}

variable "owner" {
  description = "Email distribution list for team responsible for developing and maintaining service​"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC. Must a subset of your private subnets."
  type        = list(string)
}

variable "enable_ssm_endpoints" {
  description = "Flag to Enable system manager endpoints"
  default     = false
  type        = string
}

variable "tag_aws_map_server_id" {
  description = "Default server id, Tag for GCP to AWS migration"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC."
  type        = list(string)
}

variable "enable_vpc_flowlogs" {
  description = "Enables VPC flow logs (only required in production)"
  type        = bool
  default     = false
}

variable "log_shipping_details" {
  description = "Log Shipping details for DataDog"
  type        = object({ destination_arn = string, role_arn = string })
}
