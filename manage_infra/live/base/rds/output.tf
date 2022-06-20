
output "cluster_resource_id" {
  description = "The RDS cluster resource id"
  value       = module.rds-postgres.this_rds_cluster_resource_id
}

output "service_connect_policy_arn" {
  description = "The RDS connect policy ARN"
  value       = module.rds-postgres.this_service_connect_policy
}

output "cluster_endpoint" {
  description = "The RDS ppostgres cluster endpoint"
  value       = module.rds-postgres.this_rds_cluster_endpoint
}

output "cluster_resource_arn" {
  description = "The RDS ppostgres cluster resource ARN"
  value       = module.rds-postgres.this_rds_cluster_arn
}

output "this_rds_cluster_master_password" {
  description = "The RDS ppostgres cluster connect password"
  value       = module.rds-postgres.this_rds_cluster_master_password
}

output "this_rds_cluster_instance_endpoints" {
  description = "A list of all RDS cluster actual instances like reader and writers host details"
  value       = module.rds-postgres.this_rds_cluster_instance_endpoints
}