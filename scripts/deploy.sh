#!/bin/bash
set -e

echo "=========================================="
echo "  Fraud Detection RFT - Automated Deploy"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

command -v aws >/dev/null 2>&1 || { 
  echo -e "${RED}❌ AWS CLI required but not installed.${NC}"
  echo "Install: https://aws.amazon.com/cli/"
  exit 1
}
echo -e "${GREEN}✓${NC} AWS CLI installed"

command -v terraform >/dev/null 2>&1 || { 
  echo -e "${RED}❌ Terraform required but not installed.${NC}"
  echo "Install: https://www.terraform.io/downloads"
  exit 1
}
echo -e "${GREEN}✓${NC} Terraform installed"

command -v python3 >/dev/null 2>&1 || { 
  echo -e "${RED}❌ Python 3 required but not installed.${NC}"
  exit 1
}
echo -e "${GREEN}✓${NC} Python 3 installed"

# Verify AWS credentials
echo ""
echo "Verifying AWS credentials..."
if ! AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null); then
  echo -e "${RED}❌ AWS credentials not configured${NC}"
  echo "Run: aws configure"
  exit 1
fi
echo -e "${GREEN}✓${NC} AWS credentials valid"

AWS_REGION=${AWS_REGION:-us-east-1}
echo ""
echo -e "${GREEN}AWS Account:${NC} $AWS_ACCOUNT_ID"
echo -e "${GREEN}AWS Region:${NC} $AWS_REGION"
echo ""

# Check Bedrock access
echo "Checking Bedrock access..."
if aws bedrock list-foundation-models --region $AWS_REGION >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Bedrock access enabled"
else
  echo -e "${YELLOW}⚠${NC}  Bedrock access may not be enabled"
  echo "Enable at: https://console.aws.amazon.com/bedrock/"
  read -p "Continue anyway? (y/n): " continue_deploy
  if [ "$continue_deploy" != "y" ]; then
    exit 1
  fi
fi
echo ""

# Step 1: Create Terraform backend (if not exists)
echo "Step 1: Setting up Terraform backend..."
BACKEND_BUCKET="terraform-state-${AWS_ACCOUNT_ID}"

if ! aws s3 ls "s3://${BACKEND_BUCKET}" 2>/dev/null; then
    echo "Creating S3 bucket for Terraform state..."
    aws s3 mb "s3://${BACKEND_BUCKET}" --region $AWS_REGION
    aws s3api put-bucket-versioning \
        --bucket $BACKEND_BUCKET \
        --versioning-configuration Status=Enabled
    
    # Create DynamoDB table for state locking
    aws dynamodb create-table \
        --table-name terraform-state-lock \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION || true
fi

echo "✓ Terraform backend ready"
echo ""

# Step 2: Deploy infrastructure
echo "Step 2: Deploying infrastructure with Terraform..."
cd infrastructure

# Initialize Terraform
terraform init \
    -backend-config="bucket=${BACKEND_BUCKET}" \
    -backend-config="key=fraud-detection/terraform.tfstate" \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="encrypt=true" \
    -backend-config="dynamodb_table=terraform-state-lock"

# Plan
terraform plan -out=tfplan

# Apply
read -p "Apply Terraform plan? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply tfplan
else
    echo "Deployment cancelled"
    exit 0
fi

# Get outputs
ALB_DNS=$(terraform output -raw alb_dns_name)
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

cd ..

echo "✓ Infrastructure deployed"
echo ""

# Step 3: Generate training data
echo "Step 3: Generating sample training data..."
cd data
python3 generate_sample_data.py
cd ..

echo "✓ Training data generated"
echo ""

# Step 4: Upload training data to S3
echo "Step 4: Uploading training data to S3..."
aws s3 cp data/training/fraud_samples.jsonl "s3://${S3_BUCKET}/training-data/"
aws s3 cp data/test/test_transactions.jsonl "s3://${S3_BUCKET}/test-data/"

echo "✓ Training data uploaded"
echo ""

# Step 5: Build and push Docker image (optional)
echo "Step 5: Building API Docker image..."
cd api
docker build -t fraud-detection-api:latest .
cd ..

echo "✓ Docker image built"
echo ""

echo "==================================="
echo "Deployment Complete!"
echo "==================================="
echo ""
echo "API Endpoint: http://${ALB_DNS}/score"
echo "S3 Bucket: ${S3_BUCKET}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo ""
echo "Next steps:"
echo "1. Train RFT model: cd model && python train_rft.py --dataset ../data/training/fraud_samples.jsonl --bucket ${S3_BUCKET}"
echo "2. Test API: curl http://${ALB_DNS}/health"
echo "3. Deploy dashboard: cd dashboard && npm install && npm run dev"
echo ""


echo ""
echo "=========================================="
echo "  🎉 Deployment Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}API Endpoint:${NC} http://${ALB_DNS}/score"
echo -e "${GREEN}Health Check:${NC} http://${ALB_DNS}/health"
echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for EC2 instances to be ready"
echo "2. Test health: curl http://${ALB_DNS}/health"
echo "3. Test API: bash scripts/test_api.sh http://${ALB_DNS}"
echo "4. View logs: aws logs tail /aws/ec2/fraud-detection-rft --follow"
echo ""
echo -e "${YELLOW}💰 Remember to destroy resources when done:${NC}"
echo "   cd infrastructure && terraform destroy"
echo ""
