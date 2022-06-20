output "domain_cert_arn" {
  description = "ARN of the domain cert created by ACM"
  value       = module.create-domain-cert.domain_cert_arn
}
