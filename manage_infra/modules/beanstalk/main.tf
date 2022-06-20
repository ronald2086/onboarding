locals {
  ec2_role_name    = "enl-${var.service}-${var.region}-ebs-ec2-role"
  ec2_profile_name = "enl-${var.service}-${var.region}-ebs-ec2-profile"
  s3_bucket_name   = "enl-${var.service}-${var.region}-${var.environment}-app-artifacts"
  access_log_bucket_name         = "enl-${var.service}-${var.region}-${var.environment}-access-logs"
  account_id       = data.aws_caller_identity.current.account_id
  s3_access_roles = [
    "arn:aws:iam::${local.account_id}:role/Deployer",
    "arn:aws:iam::${local.account_id}:role/Administrator",
    "arn:aws:iam::${local.account_id}:role/${local.ec2_role_name}"
  ]
  version                        = "1.0"
  application_deployment_version = "${var.service}-${substr(filemd5(var.manage_application_bundle), 0, 10)}-${basename(var.manage_application_bundle)}"

  tags = {
    Application              = var.service
    Service                  = var.service
    Environment              = var.environment
    Owner                    = var.owner
    Terraform                = true
    aws-migration-project-id = module.common_tags.tags["aws-migration-project-id"]
    map-migrated             = var.default_map_server_id
    Version                  = "1.0"
  }
  site_con_manage_consumer_cert_ssm     = var.site_con_manage_consumer_cert_ssm
  site_con_manage_consumer_cert_key_ssm = var.site_con_manage_consumer_cert_key_ssm

  aws_ssm_policy         = "${var.service}-${var.region}-${var.environment}-ssm-policy"
  aws_cloud_watch_policy = "${var.service}-${var.region}-${var.environment}-cloud-watch-policy"

  enable_log_forwarding = var.enable_log_forwarding
  ebs_log_subscription_filter_map = local.enable_log_forwarding ? {
    "eb_activity_logs_filter"  = "/var/log/eb-activity.log",
    "httpd_access_logs_filter" = "/var/log/httpd/access_log",
    "httpd_error_logs_filter"  = "/var/log/httpd/error_log",
    "nginx_access_logs_filter" = "/var/log/nginx/access.log"
    "nginx_errror_logs_filter" = "/var/log/nginx/error.log"
  } : {}
  log_shipping_details = var.log_shipping_details

  private_key_file           = var.private_key_file
  private_cert_file          = var.private_cert_file
  beanstalk_environment_name = "${var.service}-env"
  http_sg_name               = "${var.service}-${var.region}-${var.environment}-sg"
}

data "aws_caller_identity" "current" {}

module "common_tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = local.s3_bucket_name
  tag_application   = var.service
  tag_environment   = var.environment
  tag_owner         = var.owner
  tag_service       = var.service
  tag_map_server_id = var.default_map_server_id
  tag_version       = local.version
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
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
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.s3_access_roles
    }
  }
}

# To check if S3 bucket already exists
data "external" "s3-bucket-data" {
  program = ["bash", "-c",
    format("aws s3api list-buckets --query \"Buckets[?Name=='%s'].{name:Name}[0]\"", local.s3_bucket_name)
  ]
}

module "s3_bucket" {
  source        = "git::ssh://git@bitbucket.org/enlightedinc/terraform-aws-s3-bucket.git?ref=tags/v1.17.0"
  create_bucket = true
  bucket        = local.s3_bucket_name
  tags          = module.common_tags.tags

  force_destroy = true

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = local.access_log_bucket_name
    target_prefix = "App-Artifacts-S3-Access-Logs/"
  }

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

################### ------- start s3 certs config file builder ------#################

resource "null_resource" "s3_cert_and_key_replace_script" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/ssl_s3_config_builder.sh '${var.region}' '${local.s3_bucket_name}' '${local.ec2_role_name}' '${var.manage_application_bundle}' '${path.module}/.ebextensions/ssl-cert-key-from-s3.config' '${path.module}/.ebextensions/httpd/conf.d/ssl_443_listener.conf' '${var.service}'"
  }
}

################### ------- end s3 certs config file builder ------#################

resource "aws_s3_bucket_object" "this" {
  key = basename(var.manage_application_bundle)

  bucket                 = local.s3_bucket_name
  source                 = var.manage_application_bundle
  server_side_encryption = "AES256"
  tags                   = module.common_tags.tags

  depends_on = [module.s3_bucket, null_resource.s3_cert_and_key_replace_script]
}


####################-------------------------------------------##################
#                    ssl cert and keys for apache server
####################-------------------------------------------##################

resource "aws_s3_bucket_object" "private_key" {
  key                    = basename(local.private_key_file)
  bucket                 = local.s3_bucket_name
  source                 = local.private_key_file
  server_side_encryption = "AES256"
  tags                   = module.common_tags.tags

  depends_on = [module.s3_bucket]
}

resource "aws_s3_bucket_object" "private_cert_file" {
  key                    = basename(local.private_cert_file)
  bucket                 = local.s3_bucket_name
  source                 = local.private_cert_file
  server_side_encryption = "AES256"
  tags                   = module.common_tags.tags

  depends_on = [module.s3_bucket]
}

####################-------------------------------------------##################
#                    aws-elasticbeanstalk-ec2-role
####################-------------------------------------------##################

resource "aws_iam_role" "ebs_ec2_role" {
  name                  = local.ec2_role_name
  tags                  = merge(module.common_tags.tags, { "Name" = "${var.service}-aws-ebs-ec2-role" })
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ebs_ec2_profile" {
  name = local.ec2_profile_name
  role = aws_iam_role.ebs_ec2_role.name
}

resource "aws_iam_policy_attachment" "ebs_ec2_worker" {
  name       = "enl-${var.service}-${var.region}-ebs-ec2-worker"
  roles      = [aws_iam_role.ebs_ec2_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_web" {
  name       = "enl-${var.service}-${var.region}-ebs-ec2-web"
  roles      = [aws_iam_role.ebs_ec2_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_container" {
  name       = "enl-${var.service}-${var.region}-ebs-ec2-container"
  roles      = [aws_iam_role.ebs_ec2_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_policy_attachment" "beanstalk_admin_access_to_ec2_role" {
  name       = "enl-${var.service}-${var.region}-ebs-admin-access-to-ec2-role"
  roles      = [aws_iam_role.ebs_ec2_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
}

resource "aws_iam_role_policy_attachment" "ssm_activation_policy" {
  role       = aws_iam_role.ebs_ec2_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// --------------- manage s3 bucket access policy ------------------------------
data "aws_iam_policy_document" "s3_access_to_ec2_isntance_role_policy_document" {
  statement {
    actions = [
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access_to_ec2_isntance_role_policy" {
  name        = "${var.service}-${var.region}-s3-access-to-ec2-role-policy"
  path        = "/"
  description = "Allow access to Manage application S3 access"
  policy      = data.aws_iam_policy_document.s3_access_to_ec2_isntance_role_policy_document.json
}

resource "aws_iam_policy_attachment" "beanstalk_s3_access_to_ec2_role" {
  name       = "enl-${var.service}-${var.region}-s3-access-to-ec2-role"
  roles      = [aws_iam_role.ebs_ec2_role.id]
  policy_arn = aws_iam_policy.s3_access_to_ec2_isntance_role_policy.arn
}

data "aws_iam_policy_document" "aws_ssm_ec2" {
  statement {
    actions = [
      #required to access secrets for manage from beanstalk ec2 instance
      "ssm:GetParameter",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/${var.service}-cert",
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/${var.service}-key"
    ]
  }
}

resource "aws_iam_policy" "aws_ssm_ec2" {
  name = local.aws_ssm_policy

  path        = "/"
  description = "Allow lambda access to ssm store"
  policy      = data.aws_iam_policy_document.aws_ssm_ec2.json
}

resource "aws_iam_role_policy_attachment" "aws_ssm_ec2" {
  role       = aws_iam_role.ebs_ec2_role.name
  policy_arn = aws_iam_policy.aws_ssm_ec2.arn
}

data "aws_iam_policy_document" "aws_cloud_watch_ec2" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "aws_cloud_watch_ec2" {
  name        = local.aws_cloud_watch_policy
  path        = "/"
  description = "Allow access to write to cloud watch"
  policy      = data.aws_iam_policy_document.aws_cloud_watch_ec2.json
}

resource "aws_iam_role_policy_attachment" "aws_cloud_watch_ec2" {
  role       = aws_iam_role.ebs_ec2_role.name
  policy_arn = aws_iam_policy.aws_cloud_watch_ec2.arn
}

resource "aws_cloudwatch_log_group" "ems_cloud_watch_log_group" {
  name              = "/aws/elasticbeanstalk/${local.beanstalk_environment_name}/ems"
  retention_in_days = 30
}

####################-------------------------------------------##################
#                    aws-elasticbeanstalk-service-role
####################-------------------------------------------##################

resource "aws_iam_role" "ebs_service_role" {
  name                  = "enl-${var.service}-${var.region}-ebs-service-role"
  tags                  = merge(module.common_tags.tags, { "Name" = "${var.service}-aws-ebs-service-role" })
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ebs_service_profile" {
  name = "enl-${var.service}-${var.region}-ebs-service-profile"
  role = aws_iam_role.ebs_service_role.name
}

resource "aws_iam_policy_attachment" "ebs_service" {
  name       = "enl-${var.service}-${var.region}-ebs-service"
  roles      = [aws_iam_role.ebs_service_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_policy_attachment" "beanstalk_service_health" {
  name       = "enl-${var.service}-${var.region}-ebs-service-health"
  roles      = [aws_iam_role.ebs_service_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}


resource "aws_iam_policy_attachment" "beanstalk_admin_access_service" {
  name       = "enl-${var.service}-${var.region}-ebs-admin-access-to-service-role"
  roles      = [aws_iam_role.ebs_service_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
}

####################-------------------------------------------##################
#                    beanstalk resources
####################-------------------------------------------##################

resource "aws_elastic_beanstalk_application" "eb_application" {
  name        = "${var.service}-app"
  description = "${var.service} application"
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(module.common_tags.tags, { Name = "${var.service}-app" })
}


resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = local.application_deployment_version
  description = "${var.service} application version created by terraform"
  bucket      = module.s3_bucket.this_s3_bucket_id
  key         = aws_s3_bucket_object.this.id
  application = aws_elastic_beanstalk_application.eb_application.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_s3_bucket_object.this]

  tags = merge(module.common_tags.tags, { Name = local.application_deployment_version })
}

resource "aws_elastic_beanstalk_environment" "eb_environment" {
  name                = local.beanstalk_environment_name
  application         = aws_elastic_beanstalk_application.eb_application.id
  solution_stack_name = var.environment_stack_name
  tier                = "WebServer"
  depends_on          = [aws_elastic_beanstalk_application_version.app_version, aws_cloudwatch_log_group.ems_cloud_watch_log_group, aws_s3_bucket_object.private_key, aws_s3_bucket_object.private_cert_file, aws_security_group.manage_port80_sg]
  version_label       = local.application_deployment_version

  #================================================Configure Environment Variables ====================
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENL_APP_HOME"
    value     = var.manage_application_files_path
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "user.timezone"
    value     = var.tenant_instance_timezone
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = var.region
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_CLUSTER_HOST"
    value     = var.manage_database_endpoint
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USER"
    value     = var.manage_database_username
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = var.manage_database_password
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ems.deployment.env"
    value     = "aws"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "spring.profiles.active"
    value     = "aws"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ems.webapp.deployment.path"
    value     = "/var/lib/tomcat8/webapps/ems/"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SITE_CON_CONSUMER_PRI_CERT_SSM_NAME"
    value     = local.site_con_manage_consumer_cert_ssm
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SITE_CON_CONSUMER_PRI_CERT_KEY_SSM_NAME"
    value     = local.site_con_manage_consumer_cert_key_ssm
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ems.uuid"
    value     = var.manage_uuid
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ems.aws.mqtt.endpoint"
    value     = var.iot_core_endpoint
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ems.aws.mqtt.adapter.flag_use_republished_topics"
    value     = var.feature_flag_use_republished_topics
  }
  #================================================Configure Custom VPC for Instances ====================
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = true
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.elb_public_subnets)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.private_subnets)
  }
  #================================================Configure Elastic Compute Instances ===================
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instance_type
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ebs_ec2_profile.name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = var.ebs_root_volume_size_in_gb
  }
  #================================================eb environment=========================================
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.ebs_service_role.name
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
    resource  = ""
  }
  #==============================================Enabling Listener Port (443) on ALB=================================
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.domain_certificate_arn
    resource  = ""
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = true
    resource  = ""
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
    resource  = ""
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }


  #==============================================Enabling Default Listener Port (80) on ALB==========================
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = var.enable_port_80_http_redirect
    resource  = ""
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerEnabled"
    value     = var.enable_port_80_http_redirect
    resource  = ""
  }
  #================================================Environment Default Process=======================================
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/ems/heartbeat.jsp"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = var.application_port
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTPS"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "StickinessEnabled"
    value     = true
    resource  = ""
  }
  #================================================enabling cloudwatch logs for EBS=====================================
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = var.enable_stream_logs ? "true" : "false"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = var.logs_delete_on_terminate ? "true" : "false"
    resource  = ""
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.logs_retention_in_days
    resource  = ""
  }
  #================================================Variable for .ebextension Files=====================================
  setting {
    name      = "JVMOptions"
    namespace = "aws:cloudformation:template:parameter"
    value     = var.tomcat_jvm_parameters
  }
  #================================================Configure ALB=======================================
  dynamic "setting" {
    for_each = var.enable_port_80_http_redirect ? [1] : []
    content {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = aws_security_group.manage_port80_sg[0].id
    }
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Enabled"
    value     = var.enable_alb_access_logs
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Bucket"
    value     = module.s3_access_logs_bucket.this_s3_bucket_id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Prefix"
    value     = "ALB-Access-Logs"
  }

  #-------------------- enhanced health reporting ------------------------------
  #-------------------- here 60 is in seconds and minimum value accepting from terraform

  setting {
    name      = "ConfigDocument"
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    resource  = ""
    value = jsonencode(
      {
        CloudWatchMetrics = {
          Environment = {
            ApplicationRequests4xx = 60
            ApplicationRequests5xx = 60
            InstancesOk            = 60
            InstancesWarning       = 60
          }
          Instance = {
            ApplicationRequests4xx   = 60
            ApplicationRequests5xx   = 60
            ApplicationRequestsTotal = 60
            InstanceHealth           = 60
            RootFilesystemUtil       = 60
          }
        }
        Version = 1
      }
    )
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "EnhancedHealthAuthEnabled"
    value     = "true"
    resource  = ""
  }
  #================================================Env auto scaling configuration======================================
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 1
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group" "manage_port80_sg" {
  count       = var.enable_port_80_http_redirect ? 1 : 0
  name        = local.http_sg_name
  description = "Allow inbound traffic on port Manage 80 for 443 redirect to work"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Redirect HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.common_tags.tags, { Name = "${var.service}-http-80-redirect-sg" })
  lifecycle {
    create_before_destroy = true
  }
}

module "alb_port_80_listener" {
  count                        = var.enable_port_80_http_redirect ? 1 : 0
  source                       = "../alb_port_80_listener"
  beanstalk_load_balancers_arn = element(tolist(aws_elastic_beanstalk_environment.eb_environment.load_balancers), 0)
  depends_on                   = [aws_elastic_beanstalk_environment.eb_environment]
}

module "aws_common_data" {
  source = "git::ssh://git@bitbucket.org/enlightedinc/terraform-aws-common-data.git?ref=v0.6.2"
}

resource "aws_cloudwatch_log_subscription_filter" "ebs_logs_datadog_filter" {
  for_each        = local.ebs_log_subscription_filter_map
  name            = "${aws_elastic_beanstalk_environment.eb_environment.name}_${each.key}"
  log_group_name  = "/aws/elasticbeanstalk/${aws_elastic_beanstalk_environment.eb_environment.name}${each.value}"
  role_arn        = local.log_shipping_details.role_arn
  filter_pattern  = ""
  destination_arn = local.log_shipping_details.destination_arn
}

data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    sid = "access-logs-bucket_policy"
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.access_log_bucket_name}/*",
    ]
    principals {
      identifiers = [data.aws_elb_service_account.main.arn, "arn:aws:iam::${local.account_id}:root"]
      type        = "AWS"
    }
  }
}

data "aws_elb_service_account" "main" {}

module "s3_access_logs_bucket" {
  source        = "git::ssh://git@bitbucket.org/enlightedinc/terraform-aws-s3-bucket.git?ref=tags/v1.17.0"
  create_bucket = true
  bucket        = local.access_log_bucket_name
  tags          = merge(module.common_tags.tags, { Name = local.access_log_bucket_name })

  acl           = "log-delivery-write"
  force_destroy = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [{
    id      = "log_retention_rule",
    enabled = true,
    tags = merge(module.common_tags.tags, { Name = local.access_log_bucket_name }),
    expiration = {
      days = 30
    }
  }]

  attach_policy = true
  policy        = data.aws_iam_policy_document.access_logs_bucket_policy.json
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
