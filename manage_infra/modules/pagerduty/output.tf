output "pagerduty_sns_topic_arn" {
  value       = aws_sns_topic.pagerduty.arn
  description = "arn of the pagerduty sns topic where all alarms will be published from cloudwatch"
}