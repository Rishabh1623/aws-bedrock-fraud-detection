# Deployment Guide

## Prerequisites

- AWS Account with Bedrock access
- AWS CLI configured
- Terraform >= 1.0
- Python 3.9+
- Node.js 18+

## Step 1: Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

This creates:
- DynamoDB table for transaction logs
- S3 bucket for model artifacts
- IAM roles and policies
- SNS topic for alerts
- EventBridge rules
- CloudWatch log groups

## Step 2: Generate Training Data

```bash
cd data
python generate_sample_data.py
```

This creates:
- `data/training/fraud_samples.jsonl` (1000 samples)
- `data/test/test_transactions.jsonl` (200 samples)

## Step 3: Train RFT Model

```bash
cd model
pip install -r requirements.txt

python train_rft.py \
  --dataset ../data/training/fraud_samples.jsonl \
  --bucket YOUR_S3_BUCKET_NAME \
  --model anthropic.claude-3-haiku-20240307-v1:0
```

Training takes 2-4 hours. Monitor in AWS Console: Bedrock > Custom models

## Step 4: Deploy API

```bash
cd api
npm install

# Update lambda_function.py with your RFT model ID
# MODEL_ID = 'your-custom-model-id'

# Deploy using SAM or Terraform
sam build
sam deploy --guided
```

## Step 5: Launch Dashboard

```bash
cd dashboard
npm install

# Update src/App.jsx with API Gateway endpoint
npm run dev
```

Access at http://localhost:5173

## Step 6: Test the System

```bash
# Test API endpoint
curl -X POST https://YOUR_API_GATEWAY_URL/score \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "transaction_id": "TEST123",
      "amount": 1500.00,
      "merchant": "UNKNOWN_MERCHANT",
      "location": "Foreign Country",
      "card_present": false,
      "recent_transaction_count": 10
    }
  }'
```

Expected response:
```json
{
  "transaction_id": "TEST123",
  "risk_score": 0.92,
  "risk_level": "HIGH",
  "explanation": "High risk due to large amount, unknown merchant, and multiple recent transactions",
  "latency_ms": 78.5
}
```

## Monitoring

- CloudWatch Logs: `/aws/lambda/fraud-detection-rft-fraud-detection`
- DynamoDB: Check `fraud-detection-rft-transactions` table
- SNS: Subscribe to `fraud-detection-rft-fraud-alerts` topic

## Cost Estimation

- Bedrock RFT training: ~$50-100 (one-time)
- Lambda invocations: $0.0001 per transaction
- DynamoDB: $0.25 per million writes
- S3: $0.023 per GB

Estimated monthly cost for 1M transactions: ~$150
