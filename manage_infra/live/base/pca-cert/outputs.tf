output "ssm_private_key_name" {
  description = "Manage IoT Core Privatse Key"
  value       = module.pca-cert.ssm_private_key_name
}

output "ssm_private_certficate_name" {
  description = "Manage IoT Core Privatse Key"
  value       = module.pca-cert.ssm_private_certficate_name
}

output "iot_consumer_cert_arn" {
  description = "Arn of the IoT consumer certificate"
  value       = module.pca-cert.iot_consumer_cert_arn
}

output "private_key_file" {
  description = "The file path of manage cert related private key"
  value       = module.pca-cert.private_key_file
}

output "private_cert_file" {
  description = "The file path of manage ssl certificate"
  value       = module.pca-cert.private_cert_file
}