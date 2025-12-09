terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration - using local state for initial deployment
  # Uncomment and configure S3 backend for production team collaboration
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "fraud-detection/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner_email
      CostCenter  = "ML-Innovation"
    }
  }
}

# DynamoDB for transaction audit log
resource "aws_dynamodb_table" "transactions" {
  name           = "${var.project_name}-transactions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "transaction_id"
  range_key      = "timestamp"

  attribute {
    name = "transaction_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Project = var.project_name
  }
}

# S3 bucket for training data and model artifacts
resource "aws_s3_bucket" "model_artifacts" {
  bucket = "${var.project_name}-model-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.transactions.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.fraud_alerts.arn
      }
    ]
  })
}

# SNS topic for fraud alerts
resource "aws_sns_topic" "fraud_alerts" {
  name = "${var.project_name}-fraud-alerts"

  tags = {
    Project = var.project_name
  }
}

# EventBridge rule for high-risk transactions
resource "aws_cloudwatch_event_rule" "high_risk_transactions" {
  name        = "${var.project_name}-high-risk"
  description = "Trigger on high-risk fraud scores"

  event_pattern = jsonencode({
    source      = ["custom.frauddetection"]
    detail-type = ["Transaction Scored"]
    detail = {
      risk_score = [{
        numeric = [">", 0.8]
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.high_risk_transactions.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.fraud_alerts.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/lambda/${var.project_name}-fraud-detection"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}

data "aws_caller_identity" "current" {}
