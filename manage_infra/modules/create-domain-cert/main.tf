provider "aws" {
  alias = "dns"
  assume_role {
    role_arn = "arn:aws:iam::${var.network_account_number}:role/ManageZoneDeployer"
  }
  region = var.region
}

locals {
  cert_sans = []
}

module "manage_domain_tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = var.manage_domain
  tag_application   = var.service
  tag_environment   = var.environment
  tag_owner         = var.owner
  tag_service       = var.service
  tag_map_server_id = var.default_map_server_id
}

data "aws_route53_zone" "root_domain" {
  provider     = aws.dns
  name         = var.root_domain
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.manage_domain
  validation_method         = "DNS"
  subject_alternative_names = local.cert_sans
  tags                      = module.manage_domain_tags.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.dns
  count    = length(local.cert_sans) + 1
  name     = element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_name, count.index)
  type     = element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_type, count.index)
  records  = [element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_value, count.index)]
  zone_id  = data.aws_route53_zone.root_domain.zone_id
  ttl      = 60
}

# validate the sub domain certificate using route53 DNS method
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation.*.fqdn

  timeouts {
    create = "45m"
  }
}
