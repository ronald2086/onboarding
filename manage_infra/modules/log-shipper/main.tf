data "aws_caller_identity" "current" {}

locals {
  service         = var.service
  environment     = var.environment
  region          = var.region
  owner           = var.owner
  datadog_api_key = var.datadog_api_key

  account_id     = data.aws_caller_identity.current.account_id
  s3_bucket_name = "${local.service}-${local.region}-${local.environment}-logs"
}

module "common_tags" {
  source          = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name        = ""
  tag_application = local.service
  tag_environment = local.environment
  tag_owner       = local.owner
  tag_service     = local.service
}

# Firehose Delivery Stream to ship logs to Datadog
resource "aws_kinesis_firehose_delivery_stream" "log_delivery_stream" {
  name        = "${local.service}-${local.region}-${local.environment}-log-delivery-stream"
  destination = "http_endpoint"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_stream_role.arn
    bucket_arn         = module.s3_bucket.this_s3_bucket_arn
    compression_format = "GZIP"
  }

  http_endpoint_configuration {
    url                = "https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input"
    name               = "Datadog Log Delivery"
    access_key         = local.datadog_api_key
    buffering_size     = 4
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_stream_role.arn
    s3_backup_mode     = "FailedDataOnly"

    request_configuration {
      content_encoding = "GZIP"

      common_attributes {
        name  = "amaze_service_id"
        value = local.service
      }

      common_attributes {
        name  = "amaze_environment"
        value = local.environment
      }

      common_attributes {
        name  = "account"
        value = local.account_id
      }
    }
  }

  tags = merge(module.common_tags.tags, { "Name" : "LogDeliveryStream" })
}

# Firehose Role that allows the firehose to put failed logs on the bucket
resource "aws_iam_role" "firehose_stream_role" {
  name = "${local.service}-${local.region}-${local.environment}-firehose-stream-role"

  assume_role_policy = templatefile("${path.module}/templates/service_assume_role_policy.tpl.json", {
    service_url = "firehose.amazonaws.com"
  })

  inline_policy {
    name = "put_logs_in_s3_bucket"
    policy = templatefile("${path.module}/templates/firehose_to_s3_policy.tpl.json", {
      s3_bucket_name = local.s3_bucket_name
    })
  }

  tags = merge(module.common_tags.tags, { "Name" : "LogDeliveryRole" })
}

# Failed log bucket
module "s3_bucket" {
  source        = "git::ssh://git@bitbucket.org/enlightedinc/terraform-aws-s3-bucket.git?ref=tags/v1.13.0"
  create_bucket = true
  bucket        = local.s3_bucket_name
  tags          = merge(module.common_tags.tags, { Name = local.s3_bucket_name })

  acl           = "log-delivery-write"
  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Log Subscription Role that allows Cloudwatch Logs to put records on the firehose
resource "aws_iam_role" "log_subscription_delivery_role" {
  name = "${local.service}-${local.region}-${local.environment}-log-delivery-role"

  assume_role_policy = templatefile("${path.module}/templates/service_assume_role_policy.tpl.json", {
    service_url = "logs.amazonaws.com"
  })

  inline_policy {
    name = "deliver_logs_to_firehose_policy"
    policy = templatefile("${path.module}/templates/log_subscription_delivery_policy.tpl.json", {
      delivery_stream_arn = aws_kinesis_firehose_delivery_stream.log_delivery_stream.arn
    })
  }

  tags = merge(module.common_tags.tags, { "Name" : "SubscriptionDeliveryRole" })
}
