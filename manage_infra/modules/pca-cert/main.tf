provider "aws" {
  alias = "pca"
  assume_role {
    role_arn = local.network_role_arn
  }
  region = local.region
}

locals {
  service                = var.service
  region                 = var.region
  environment            = var.environment
  owner                  = var.owner
  default_map_server_id  = var.default_map_server_id
  manage_uuid            = var.manage_uuid
  network_account_number = var.network_account_number

  pca_arn            = var.pca_arn
  tenant_instance    = var.tenant_instance
  pk_passphrase_file = "${path.module}/passphrase"
  private_key_file   = "${path.module}/scripts/private_key.txt"
  private_cert_file  = "${path.module}/scripts/private_cert.txt"
  export_cert_role   = var.environment == "prod" ? "ManageCertDeployerProd" : "ManageCertDeployer"
  network_role_arn   = "arn:aws:iam::${local.network_account_number}:role/${local.export_cert_role}"
}

data "aws_acmpca_certificate_authority" "pca" {
  provider = aws.pca
  arn      = local.pca_arn
}

module "common_tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = local.tenant_instance
  tag_application   = local.service
  tag_environment   = local.environment
  tag_owner         = local.owner
  tag_service       = local.service
  tag_map_server_id = local.default_map_server_id
  tag_version       = 1
}

resource "aws_acm_certificate" "iot_consumer_cert" {
  provider                  = aws.pca
  domain_name               = "${local.service}.com"
  certificate_authority_arn = local.pca_arn
  tags                      = module.common_tags.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "local_file" "passphrase" {
  content  = var.manage_uuid
  filename = local.pk_passphrase_file
}

resource "null_resource" "export_cert_and_key" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/exportCert.sh '${local.network_role_arn}' '${local.region}' '${aws_acm_certificate.iot_consumer_cert.arn}' '${local.pk_passphrase_file}' '${local.private_key_file}' '${local.private_cert_file}'"
  }
  depends_on = [aws_acm_certificate.iot_consumer_cert, local_file.passphrase]
}

data "local_file" "private_key" {
  filename   = local.private_key_file
  depends_on = [null_resource.export_cert_and_key]
}

data "local_file" "private_cert" {
  filename   = local.private_cert_file
  depends_on = [null_resource.export_cert_and_key]
}

resource "aws_ssm_parameter" "private_key_ssm" {
  name        = "${local.tenant_instance}-manage-key"
  description = "Private Cert Key for Manage Instance"
  type        = "SecureString"
  value       = data.local_file.private_key.content
  overwrite   = "true"
  tags        = merge(module.common_tags.tags, { "Name" = "Manage Private Key", "Version" = "1.0" })
  depends_on  = [null_resource.export_cert_and_key]
}

resource "aws_ssm_parameter" "private_cert_ssm" {
  name        = "${local.tenant_instance}-manage-cert"
  description = "Private Cert for Manage Instance"
  type        = "SecureString"
  value       = data.local_file.private_cert.content
  overwrite   = "true"
  tags        = merge(module.common_tags.tags, { "Name" = "Manage Private Cert", "Version" = "1.0" })
  depends_on  = [null_resource.export_cert_and_key]
}
