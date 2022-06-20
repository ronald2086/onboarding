output "env_endpoint_url" {
  description = "The endpoint url of manage application"
  value       = aws_elastic_beanstalk_environment.eb_environment.endpoint_url
}

output "env_load_balancers" {
  description = "The endpoint url of manage application"
  value       = aws_elastic_beanstalk_environment.eb_environment.load_balancers
}

output "autoscaling_groups" {
  description = "The auto scaling group to check CPU utilization"
  value       = aws_elastic_beanstalk_environment.eb_environment.autoscaling_groups
}

output "load_balancers" {
  description = "The app load balancers to check http status codes"
  value       = aws_elastic_beanstalk_environment.eb_environment.load_balancers
}

output "instances" {
  description = "The beanstalk used instances"
  value       = aws_elastic_beanstalk_environment.eb_environment.instances
}

output "beanstalk_environment_name" {
  description = "The beanstalk environment name"
  value       = aws_elastic_beanstalk_environment.eb_environment.name
}

output "manage_artifacts_s3_bucket_name" {
  description = "Manage application artifacts s3 bucket name"
  value       = module.s3_bucket.this_s3_bucket_id
}

output "manage_ec2_instance_profile_name" {
  description = "The profile name will be used to communicate aws services from ec2 instance"
  value       = aws_iam_instance_profile.ebs_ec2_profile.name
}