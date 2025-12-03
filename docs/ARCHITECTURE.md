# System Architecture

## Overview

Real-time fraud detection system using Amazon Bedrock RFT for adaptive learning with minimal labeled data.

## Architecture Diagram

```
┌─────────────┐
│   Client    │
│ Application │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  API Gateway    │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│  Lambda Function     │
│  - Score transaction │
│  - Store results     │
│  - Trigger alerts    │
└──────┬───────────────┘
       │
       ├──────────────────┐
       │                  │
       ▼                  ▼
┌─────────────┐    ┌──────────────┐
│   Bedrock   │    │  DynamoDB    │
│  RFT Model  │    │ Transactions │
└─────────────┘    └──────────────┘
       │
       ▼
┌─────────────────┐
│  EventBridge    │
│  (High Risk)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   SNS Topic     │
│  Fraud Alerts   │
└─────────────────┘
```

## Components

### 1. API Layer
- **API Gateway**: REST endpoint for transaction scoring
- **Lambda**: Serverless compute for fraud detection logic
- **Response Time**: <100ms target

### 2. ML Layer
- **Bedrock RFT Model**: Fine-tuned fraud detection model
- **Base Model**: Claude 3 Haiku (fast, cost-effective)
- **Training**: Automated RFT workflow on Bedrock

### 3. Data Layer
- **DynamoDB**: Transaction audit log with streams
- **S3**: Model artifacts and training data
- **Retention**: 90 days for compliance

### 4. Event Layer
- **EventBridge**: Event-driven alerts for high-risk transactions
- **SNS**: Multi-channel notifications (email, SMS, webhook)
- **CloudWatch**: Metrics and logging

### 5. Frontend
- **React Dashboard**: Real-time monitoring
- **Metrics**: Accuracy, latency, fraud rate
- **Visualization**: Risk score distribution

## Data Flow

### Transaction Scoring Flow
1. Client sends transaction to API Gateway
2. Lambda receives request
3. Lambda invokes Bedrock RFT model
4. Model returns risk score (0.0-1.0)
5. Lambda stores result in DynamoDB
6. If score > 0.8, trigger EventBridge event
7. SNS sends alert to subscribers
8. Return response to client

### Training Flow
1. Collect labeled fraud examples
2. Upload to S3 in JSONL format
3. Start Bedrock RFT job
4. Bedrock trains model (2-4 hours)
5. Deploy custom model endpoint
6. Update Lambda environment variable

## Scalability

- **Lambda**: Auto-scales to 1000 concurrent executions
- **DynamoDB**: On-demand capacity, unlimited throughput
- **Bedrock**: Managed scaling, no infrastructure
- **Expected Load**: 10,000 transactions/second

## Security

- **IAM Roles**: Least privilege access
- **Encryption**: At-rest (S3, DynamoDB) and in-transit (TLS)
- **VPC**: Optional private subnet deployment
- **Audit**: CloudTrail logging enabled

## Cost Optimization

- **Lambda**: Pay per invocation ($0.20 per 1M requests)
- **Bedrock**: Pay per token ($0.00025 per 1K tokens)
- **DynamoDB**: On-demand pricing (no idle costs)
- **Total**: ~$150/month for 1M transactions

## Monitoring

- **CloudWatch Metrics**: Latency, error rate, invocation count
- **CloudWatch Logs**: Detailed transaction logs
- **X-Ray**: Distributed tracing (optional)
- **Alarms**: Automated alerts for anomalies

## Disaster Recovery

- **RTO**: 15 minutes (redeploy Lambda)
- **RPO**: 0 (DynamoDB point-in-time recovery)
- **Backup**: S3 versioning for model artifacts
- **Multi-Region**: Deploy to secondary region for HA
