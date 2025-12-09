variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "fraud-detection-rft"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner_email" {
  description = "Email of project owner for tagging"
  type        = string
  default     = "your-email@example.com"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID for inference (use Nova Lite for RFT compatibility)"
  type        = string
  default     = "amazon.nova-lite-v1:0"
}

variable "fraud_threshold" {
  description = "Risk score threshold for fraud alerts"
  type        = number
  default     = 0.8
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH to EC2"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "ec2_instance_type" {
  description = "EC2 instance type for API server"
  type        = string
  default     = "t3.medium"
}

variable "enable_multi_az" {
  description = "Enable multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable AWS WAF for API protection"
  type        = bool
  default     = false
}
