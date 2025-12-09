# AWS WAF for API Gateway Protection

# WAF Web ACL
resource "aws_wafv2_web_acl" "api_protection" {
  name  = "${var.project_name}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: Rate limiting (prevent DDoS)
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-waf"
  }
}

# Note: WAF association with HTTP API Gateway is not supported
# HTTP APIs don't support WAF directly. For production, consider:
# 1. Use REST API instead of HTTP API (supports WAF)
# 2. Use CloudFront in front of HTTP API (CloudFront supports WAF)
# 3. Use API Gateway resource policies for IP-based access control
#
# For this demo, we keep the WAF configuration to show security awareness
# but don't associate it. In production, you'd use option 1 or 2.

# Uncomment below if using REST API (aws_api_gateway_rest_api):
# resource "aws_wafv2_web_acl_association" "api_gateway" {
#   resource_arn = aws_apigatewayv2_stage.default.arn
#   web_acl_arn  = aws_wafv2_web_acl.api_protection.arn
# }

# CloudWatch Log Group for WAF (must start with aws-waf-logs-)
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.project_name}"
  retention_in_days = 7
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "api_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.api_protection.arn
  log_destination_configs = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
}
