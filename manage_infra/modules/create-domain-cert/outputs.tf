output "domain_cert_arn" {
  description = "ARN of the domain cert created by ACM"
  value       = aws_acm_certificate.cert.arn
}
