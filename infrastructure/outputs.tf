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

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.fraud_detection.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.fraud_detection.arn
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

output "cloudwatch_dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
