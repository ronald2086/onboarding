output "ssm_private_key_name" {
  description = "Manage IoT Core Privatse Key"
  value       = aws_ssm_parameter.private_key_ssm.name
}

output "ssm_private_certficate_name" {
  description = "Manage IoT Core Privatse Key"
  value       = aws_ssm_parameter.private_cert_ssm.name
}

output "iot_consumer_cert_arn" {
  description = "Arn of the IoT consumer certificate"
  value       = aws_acm_certificate.iot_consumer_cert.arn
}

output "private_key_file" {
  description = "The file path of manage cert related private key"
  value       = local.private_key_file
}

output "private_cert_file" {
  description = "The file path of manage ssl certificate"
  value       = local.private_cert_file
}