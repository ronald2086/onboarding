output "log_shipping_details" {
  description = "The data a log subscription needs to ship put logs on the log shipper"
  value = {
    destination_arn = aws_kinesis_firehose_delivery_stream.log_delivery_stream.arn
    role_arn        = aws_iam_role.log_subscription_delivery_role.arn
  }
}
