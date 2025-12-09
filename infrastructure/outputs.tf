output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.fraud_api.api_endpoint
}

output "api_endpoint" {
  description = "Fraud detection API endpoint"
  value       = "${aws_apigatewayv2_api.fraud_api.api_endpoint}/score"
}

output "health_endpoint" {
  description = "Health check endpoint"
  value       = "${aws_apigatewayv2_api.fraud_api.api_endpoint}/health"
}

output "dynamodb_table_name" {
  description = "DynamoDB table for transactions"
  value       = aws_dynamodb_table.transactions.name
}

output "s3_bucket_name" {
  description = "S3 bucket for model artifacts"
  value       = aws_s3_bucket.model_artifacts.id
}

output "sns_topic_arn" {
  description = "SNS topic for fraud alerts"
  value       = aws_sns_topic.fraud_alerts.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.api_servers.name
}
