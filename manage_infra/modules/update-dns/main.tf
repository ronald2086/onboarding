provider "aws" {
  alias = "dns"
  assume_role {
    role_arn = "arn:aws:iam::${var.network_account_number}:role/ManageZoneDeployer"
  }
  region = var.region
}

data "aws_route53_zone" "root_domain" {
  provider     = aws.dns
  name         = var.root_domain
  private_zone = false
}

resource "aws_route53_record" "sub_domain" {
  provider = aws.dns
  name     = var.manage_domain
  type     = "CNAME"
  zone_id  = data.aws_route53_zone.root_domain.zone_id
  records  = [var.endpoint_url]
  ttl      = "60"
}
