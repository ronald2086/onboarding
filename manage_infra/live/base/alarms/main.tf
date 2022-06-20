############--------------------------------------############
#                   alarms setup                             #
############--------------------------------------############

module "common_tags" {
  source            = "git::ssh://git@bitbucket.org/enlightedinc/terraform-common-tags.git?ref=v1.1.0"
  tag_name          = "${var.service}-beanstalk-manage-alarms"
  tag_application   = var.service
  tag_environment   = var.environment
  tag_owner         = var.owner
  tag_service       = var.service
  tag_map_server_id = var.default_map_server_id
  tag_version       = "1.0"
}
############-------------------------------------------#############
#           Alarm for beanstalk CPU high utilization               #
#           CPUUtilization >= 80 for 5 datapoints within 5 minutes #
############-------------------------------------------#############
module "manage_beanstalk_instance_cpu_utilization" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-instance-cpu-utilization", var.service, var.region, var.environment)
  alarm_description   = format("%s cpu utilization alarm", var.service)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  period              = 60
  threshold           = 80
  unit                = "Percent"
  statistic           = "Average"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = var.auto_scaling_group_name
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Beanstalk Environment CPU Alarm" })
}

############------------------------------------------------------------------#############
#           Alarm for 5XX errors                                                          #
#           HTTPCode_Target_5XX_Count >= 10 for 5 datapoints within 5 minutes             #
############------------------------------------------------------------------#############

module "manage_application_5XX_errors" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-app-5XX-errors", var.service, var.region, var.environment)
  alarm_description   = format("%s application 5XX errors", var.service)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  period              = 60
  threshold           = 10
  unit                = "Count"
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = var.beanstalk_load_balancer
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Manage App 5XX Error" })
}

############------------------------------------------------------------------#############
#           Alarm for 4XX errors                                                          #
#           HTTPCode_Target_4XX_Count >= 10 for 5 datapoints within 5 minutes             #
############------------------------------------------------------------------#############

module "manage_application_4XX_errors" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-app-4XX-errors", var.service, var.region, var.environment)
  alarm_description   = format("%s application 4XX errors", var.service)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  period              = 60
  threshold           = 10
  unit                = "Count"
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_4XX_Count"

  dimensions = {
    LoadBalancer = var.beanstalk_load_balancer
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Manage App 4XX Error" })
}

/*
* beanstalk environment will be severe state if threshold value greater than 20
* FMD : https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced-cloudwatch.html
* EnvironmentHealth > 20 for 3 datapoints in 3 minute
*/
module "manage_application_env_health_status" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-app-env-healthy-status", var.service, var.region, var.environment)
  alarm_description   = format("%s application health-status", var.service)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  period              = 60
  threshold           = 20
  unit                = "None"
  statistic           = "Average"

  namespace   = "AWS/ElasticBeanstalk"
  metric_name = "EnvironmentHealth"

  dimensions = {
    EnvironmentName = var.beanstalk_environment_name
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Beanstalk App Environment Health Status" })
}


############------------------------------------------------------------------#############
#           Alarm for beanstalk storage volume                                            #
#           RootFilesystemUtil >= 80 for 2 datapoints within 2 minutes                    #
############------------------------------------------------------------------#############

module "manage_application_instance_storage_volume" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-app-storage-volume", var.service, var.region, var.environment)
  alarm_description   = format("%s app storage volume", var.service)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 80
  unit                = "Percent"
  statistic           = "Average"

  namespace   = "AWS/ElasticBeanstalk"
  metric_name = "RootFilesystemUtil"

  dimensions = {
    InstanceId      = var.beanstalk_env_instance_id,
    EnvironmentName = var.beanstalk_environment_name
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Manage Beanstalk Attached Block Storage Volume" })
}


############------------------------------------------------------------------#############
#           Alarm for RDS cpu utilization                                                 #
#           CPUUtilization >= 80 for 5 datapoints within 5 minutes                        #
############------------------------------------------------------------------#############


module "manage_application_rds_cpu_utilization" {
  source = "../../../modules/alarms/metric-alarm"

  alarm_name          = format("%s-%s-%s-rds-cpu-utilization", var.service, var.region, var.environment)
  alarm_description   = format("%s RDS high CPU utilization", var.service)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  period              = 60
  threshold           = 80
  unit                = "Percent"
  statistic           = "Average"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"


  dimensions = {
    DBClusterIdentifier = var.db_cluster_identifier
  }

  alarm_actions = [var.pager_duty_sns_topic_arn]
  tags          = merge(module.common_tags.tags, { "Name" = "Manage RDS CPU High" })

}
