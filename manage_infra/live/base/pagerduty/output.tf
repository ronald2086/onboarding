output "pagerduty_sns_topic_arn" {
  value       = module.pagerduty.pagerduty_sns_topic_arn
  description = "arn of the pagerduty sns topic where all alarms will be published from cloudwatch"
}