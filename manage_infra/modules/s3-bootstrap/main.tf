provider "aws" {
  region = var.region
}

locals {
  bucket_name       = "enl-${var.service}-${var.region}-${var.environment}-terraform"
  dynamo_table_name = format("%s-lock-%s-%s-dynamodb", var.service, var.region, var.environment)
  backup_vault_name = format("%s-bkp-%s-%s-vlt", var.service, var.region, var.environment)
}

module "common_tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = ""
  tag_application   = var.service
  tag_environment   = var.environment
  tag_owner         = var.owner
  tag_service       = var.service
  tag_map_server_id = var.default_map_server_id
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "Object-Access-denied-to-all-but-admin-and-dev-roles"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect = "Deny"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = var.access_roles
    }
  }
}

# To check if S3 bucket already exists
data "external" "s3-bucket-data" {
  program = ["bash", "-c",
    format("aws s3api list-buckets --query \"Buckets[?Name=='%s'].{name:Name}[0]\"", local.bucket_name)
  ]
}

module "s3_bucket" {
  source        = "git::ssh://git@bitbucket.org/enlightedinc/terraform-aws-s3-bucket.git?ref=tags/v1.17.0"
  create_bucket = lookup(data.external.s3-bucket-data.result, "name", null) == null ? true : false
  bucket        = local.bucket_name
  tags          = merge(module.common_tags.tags, { Name = local.bucket_name })

  acl           = "log-delivery-write"
  force_destroy = true
  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = local.bucket_name
    target_prefix = "log/"
  }

  lifecycle_rule = [{
    id      = "log",
    enabled = true,

    prefix = "log/",

    tags = merge(module.common_tags.tags, { Name = local.bucket_name }),

    expiration = {
      days = 30
    }
  }]

  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json


  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  // S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# To check if dynamo lock table exists
data "external" "dynamo-lock-table-data" {
  program = ["bash", "-c",
    format("aws dynamodb list-tables --region %s --query \"{tableExists:to_string(contains(TableNames,'%s'))}\"",
    var.region, local.dynamo_table_name)
  ]
}

resource "aws_dynamodb_table" "dynamodb-lock-table" {
  # checkov:skip=CKV_AWS_28:Backup not necessary for terraform state lock table
  count = data.external.dynamo-lock-table-data.result.tableExists == "true" ? 0 : 1
  name  = local.dynamo_table_name
  tags  = merge(module.common_tags.tags, { Name = local.dynamo_table_name, exclude_resource = "true" })

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

data "external" "backup_vault_data" {
  program = ["bash", "-c",
    format("aws backup list-backup-vaults --region %s --query \"BackupVaultList[?BackupVaultName=='%s'].{name:BackupVaultName}[0]\"", var.region, local.backup_vault_name)
  ]
}

#AWS Backup Vault
resource "aws_backup_vault" "backup_vault" {
  count = lookup(data.external.backup_vault_data.result, "name", null) == null ? 1 : 0
  name  = local.backup_vault_name
  tags  = merge(module.common_tags.tags, { Name = local.backup_vault_name })
}

