output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "http://${aws_lb.main.dns_name}/score"
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
