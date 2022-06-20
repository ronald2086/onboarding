output "env_endpoint_url" {
  description = "The endpoint url of manage application environment"
  value       = module.manage-beanstalk.env_endpoint_url
}

output "env_load_balancers" {
  description = "The endpoint url of manage application"
  value       = module.manage-beanstalk.env_load_balancers
}

output "autoscaling_groups" {
  description = "The auto dcaling group to check CPU utilization"
  value       = module.manage-beanstalk.autoscaling_groups
}

output "load_balancers" {
  description = "The app load balancers to check http status codes"
  value       = module.manage-beanstalk.load_balancers
}

output "instances" {
  description = "The beanstalk used instances"
  value       = module.manage-beanstalk.instances
}

output "beanstalk_environment_name" {
  description = "The beanstalk environment name"
  value       = module.manage-beanstalk.beanstalk_environment_name
}

output "manage_artifacts_s3_bucket_name" {
  description = "The accessible url of manage application"
  value       = module.manage-beanstalk.manage_artifacts_s3_bucket_name
}

output "manage_ec2_instance_profile_name" {
  description = "The profile name will be used to communicate aws services from ec2 instance"
  value       = module.manage-beanstalk.manage_ec2_instance_profile_name
}