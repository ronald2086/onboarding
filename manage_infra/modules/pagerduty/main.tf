locals {
  topic_name   = format("%s-%s-%s-pagerduty", var.service, var.region, var.environment)
  sns_key_name = format("%s-%s-%s-key-pagerduty", var.service, var.region, var.environment)
  display_name = "PagerDuty Topic"
  account_id   = data.aws_caller_identity.current.account_id
}

module "tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = local.topic_name
  tag_application   = var.service
  tag_environment   = var.environment
  tag_owner         = var.owner
  tag_service       = var.service
  tag_map_server_id = var.default_map_server_id
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "sns_kms_key" {
  description         = local.sns_key_name
  tags                = merge(module.tags.tags, { "Name" = local.sns_key_name })
  enable_key_rotation = true
  policy              = <<EOF
                        {
                            "Version": "2012-10-17",
                            "Id": "key-consolepolicy-3",
                            "Statement": [
                                {
                                    "Sid": "Allow_CloudWatch_for_CMK",
                                    "Effect": "Allow",
                                    "Principal": {
                                        "Service": "cloudwatch.amazonaws.com"
                                    },
                                    "Action": [
                                        "kms:Decrypt",
                                        "kms:GenerateDataKey"
                                    ],
                                    "Resource": "*"
                                },
                                {
                                    "Sid": "Allow access for Key Administrators",
                                    "Effect": "Allow",
                                    "Principal": {
                                        "AWS": [
                                                   "arn:aws:iam::${local.account_id}:role/Deployer",
                                                   "arn:aws:iam::${local.account_id}:role/Administrator"
                                                ]
                                    },
                                    "Action": [
                                        "kms:Create*",
                                        "kms:Describe*",
                                        "kms:Enable*",
                                        "kms:List*",
                                        "kms:Put*",
                                        "kms:Update*",
                                        "kms:Revoke*",
                                        "kms:Disable*",
                                        "kms:Get*",
                                        "kms:Delete*",
                                        "kms:TagResource",
                                        "kms:UntagResource",
                                        "kms:ScheduleKeyDeletion",
                                        "kms:CancelKeyDeletion"
                                    ],
                                    "Resource": "*"
                                }
                            ]
                        }
                         EOF
}


resource "aws_sns_topic" "pagerduty" {
  name              = local.topic_name
  display_name      = local.display_name
  tags              = module.tags.tags
  kms_master_key_id = aws_kms_key.sns_kms_key.key_id

}

resource "aws_sns_topic_subscription" "pagerduty" {
  endpoint               = var.pagerduty_endpoint
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = aws_sns_topic.pagerduty.arn
}
