# AWS Bedrock Fraud Detection - Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (us-east-1)                          │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                        Security Layer                            │  │
│  │                                                                  │  │
│  │  ┌──────────────┐         ┌─────────────────┐                  │  │
│  │  │   AWS WAF    │────────▶│  Rate Limiting  │                  │  │
│  │  │              │         │  (2000 req/s)   │                  │  │
│  │  │  • SQL Injection       └─────────────────┘                  │  │
│  │  │  • XSS Protection                                           │  │
│  │  │  • Bad Inputs                                               │  │
│  │  └──────┬───────┘                                              │  │
│  └─────────┼──────────────────────────────────────────────────────┘  │
│            │                                                          │
│            ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                     API Gateway (HTTP API)                      │ │
│  │                                                                 │ │
│  │  Endpoints:                                                     │ │
│  │  • POST /score  - Fraud detection                              │ │
│  │  • GET  /health - Health check                                 │ │
│  │                                                                 │ │
│  │  Features:                                                      │ │
│  │  • CORS enabled                                                 │ │
│  │  • Request validation                                           │ │
│  │  • CloudWatch logging                                           │ │
│  └─────────┬───────────────────────────────────────────────────────┘ │
│            │                                                          │
│            ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │              AWS Lambda (fraud-detection-rft-api)               │ │
│  │                                                                 │ │
│  │  Runtime: Python 3.11                                           │ │
│  │  Memory: 512 MB                                                 │ │
│  │  Timeout: 30 seconds                                            │ │
│  │                                                                 │ │
│  │  Function Logic:                                                │ │
│  │  1. Parse transaction data                                      │ │
│  │  2. Call Bedrock for risk scoring                               │ │
│  │  3. Store in DynamoDB                                           │ │
│  │  4. Trigger alerts if high risk                                 │ │
│  └─────┬───────────────┬───────────────┬───────────────────────────┘ │
│        │               │               │                             │
│        │               │               │                             │
│        ▼               ▼               ▼                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────────┐                    │
│  │ Amazon   │   │ DynamoDB │   │  EventBridge │                    │
│  │ Bedrock  │   │          │   │              │                    │
│  │          │   │ Table:   │   │  Rule:       │                    │
│  │ Model:   │   │ fraud-   │   │  High Risk   │                    │
│  │ Nova     │   │ detection│   │  Transactions│                    │
│  │ Lite     │   │ -rft-    │   │              │                    │
│  │          │   │ trans-   │   └──────┬───────┘                    │
│  │ RFT:     │   │ actions  │          │                             │
│  │ Enabled  │   │          │          ▼                             │
│  │          │   │ Stores:  │   ┌──────────────┐                    │
│  │ Latency: │   │ • Trans  │   │  SNS Topic   │                    │
│  │ <100ms   │   │   ID     │   │              │                    │
│  │          │   │ • Amount │   │  fraud-      │                    │
│  │ Cost:    │   │ • Risk   │   │  detection-  │                    │
│  │ $0.0006  │   │   Score  │   │  rft-fraud-  │                    │
│  │ per 1K   │   │ • Time   │   │  alerts      │                    │
│  │ tokens   │   │          │   │              │                    │
│  └──────────┘   └──────────┘   └──────────────┘                    │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Monitoring & Logging                      │  │
│  │                                                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │  │
│  │  │ CloudWatch  │  │ CloudWatch  │  │ CloudWatch  │        │  │
│  │  │ Logs        │  │ Metrics     │  │ Alarms      │        │  │
│  │  │             │  │             │  │             │        │  │
│  │  │ • Lambda    │  │ • Invocations│ │ • High      │        │  │
│  │  │ • API GW    │  │ • Errors    │  │   Error Rate│        │  │
│  │  │ • WAF       │  │ • Latency   │  │ • High      │        │  │
│  │  │             │  │ • Throttles │  │   Latency   │        │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Storage & Artifacts                       │  │
│  │                                                              │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │  S3 Bucket (fraud-detection-rft-model-artifacts)    │   │  │
│  │  │                                                      │   │  │
│  │  │  • Model training data                               │   │  │
│  │  │  • RFT fine-tuned models                             │   │  │
│  │  │  • Versioned artifacts                               │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

External User
     │
     │ HTTPS
     ▼
  Internet
     │
     │
     ▼
  AWS WAF ──▶ API Gateway ──▶ Lambda ──▶ Bedrock
                                  │
                                  ├──▶ DynamoDB
                                  │
                                  └──▶ EventBridge ──▶ SNS
```

---

## Request Flow Diagram

```
┌─────────┐
│  User   │
│ (Postman│
│  /curl) │
└────┬────┘
     │
     │ 1. POST /score
     │    {transaction: {...}}
     ▼
┌─────────────────┐
│    AWS WAF      │
│                 │
│ • Check rate    │
│ • Validate      │
│ • Block attacks │
└────┬────────────┘
     │
     │ 2. If allowed
     ▼
┌─────────────────┐
│  API Gateway    │
│                 │
│ • CORS check    │
│ • Log request   │
│ • Route to      │
│   Lambda        │
└────┬────────────┘
     │
     │ 3. Invoke Lambda
     ▼
┌─────────────────────────────────────┐
│         Lambda Function             │
│                                     │
│  Step 1: Parse transaction          │
│  ┌─────────────────────────────┐   │
│  │ transaction_id: "TEST001"   │   │
│  │ amount: 45.99               │   │
│  │ merchant: "Amazon"          │   │
│  │ location: "New York"        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Step 2: Build prompt               │
│  ┌─────────────────────────────┐   │
│  │ "Analyze this financial     │   │
│  │  transaction for risk..."   │   │
│  └─────────────────────────────┘   │
│           │                         │
│           │ 4. InvokeModel API      │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │    Amazon Bedrock           │   │
│  │    (Nova Lite + RFT)        │   │
│  │                             │   │
│  │  • Process prompt           │   │
│  │  • Apply RFT model          │   │
│  │  • Generate risk score      │   │
│  │  • Return explanation       │   │
│  └─────────────────────────────┘   │
│           │                         │
│           │ 5. Response             │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │ risk_score: 0.1             │   │
│  │ explanation: "Low risk..."  │   │
│  └─────────────────────────────┘   │
│                                     │
│  Step 3: Store transaction          │
│           │                         │
│           │ 6. PutItem              │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │       DynamoDB              │   │
│  │                             │   │
│  │  transaction_id: TEST001    │   │
│  │  timestamp: 1733779200      │   │
│  │  risk_score: 0.1            │   │
│  │  flagged: false             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Step 4: Check if high risk         │
│  ┌─────────────────────────────┐   │
│  │ if risk_score > 0.8:        │   │
│  │   trigger_alert()           │   │
│  └─────────────────────────────┘   │
│           │                         │
│           │ 7. PutEvents (if high)  │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │     EventBridge             │   │
│  │                             │   │
│  │  Rule: High Risk            │   │
│  │  Target: SNS Topic          │   │
│  └─────────────────────────────┘   │
│           │                         │
│           │ 8. Publish              │
│           ▼                         │
│  ┌─────────────────────────────┐   │
│  │        SNS Topic            │   │
│  │                             │   │
│  │  Send alert to subscribers  │   │
│  └─────────────────────────────┘   │
│                                     │
│  Step 5: Return response            │
│  ┌─────────────────────────────┐   │
│  │ {                           │   │
│  │   "transaction_id": "...",  │   │
│  │   "risk_score": 0.1,        │   │
│  │   "risk_level": "LOW",      │   │
│  │   "explanation": "...",     │   │
│  │   "latency_ms": 948.93      │   │
│  │ }                           │   │
│  └─────────────────────────────┘   │
└─────────┬───────────────────────────┘
          │
          │ 9. Return to API Gateway
          ▼
┌─────────────────┐
│  API Gateway    │
│                 │
│ • Log response  │
│ • Add CORS      │
│   headers       │
└────┬────────────┘
     │
     │ 10. HTTP 200 OK
     │     JSON response
     ▼
┌─────────┐
│  User   │
│ Receives│
│ Response│
└─────────┘
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      Data Lifecycle                          │
└──────────────────────────────────────────────────────────────┘

1. Transaction Input
   ┌─────────────────────────────────────────┐
   │ POST /score                             │
   │ {                                       │
   │   "transaction": {                      │
   │     "transaction_id": "TXN123",         │
   │     "amount": 1500.00,                  │
   │     "merchant": "Electronics Store",    │
   │     "location": "California",           │
   │     "card_present": false,              │
   │     "recent_transaction_count": 8       │
   │   }                                     │
   │ }                                       │
   └─────────────────────────────────────────┘
                    │
                    ▼
2. Lambda Processing
   ┌─────────────────────────────────────────┐
   │ • Validate input                        │
   │ • Extract features                      │
   │ • Build AI prompt                       │
   └─────────────────────────────────────────┘
                    │
                    ▼
3. Bedrock Analysis
   ┌─────────────────────────────────────────┐
   │ Prompt: "Analyze this financial         │
   │ transaction for risk indicators:        │
   │ - Amount: $1500.00                      │
   │ - Merchant: Electronics Store           │
   │ - Location: California                  │
   │ - Card Present: false                   │
   │ - Recent transactions: 8                │
   │                                         │
   │ Provide risk score 0.0-1.0"             │
   └─────────────────────────────────────────┘
                    │
                    ▼
4. AI Response
   ┌─────────────────────────────────────────┐
   │ "Score: 0.65 - Explanation: Moderate    │
   │ risk due to high amount ($1500) and     │
   │ card-not-present transaction. However,  │
   │ merchant is known and location is       │
   │ consistent with user history."          │
   └─────────────────────────────────────────┘
                    │
                    ▼
5. DynamoDB Storage
   ┌─────────────────────────────────────────┐
   │ Item:                                   │
   │ {                                       │
   │   "transaction_id": "TXN123",           │
   │   "timestamp": 1733779200,              │
   │   "amount": "1500.00",                  │
   │   "merchant": "Electronics Store",      │
   │   "risk_score": "0.65",                 │
   │   "explanation": "Moderate risk...",    │
   │   "flagged": false                      │
   │ }                                       │
   └─────────────────────────────────────────┘
                    │
                    ▼
6. Response to User
   ┌─────────────────────────────────────────┐
   │ HTTP 200 OK                             │
   │ {                                       │
   │   "transaction_id": "TXN123",           │
   │   "risk_score": 0.65,                   │
   │   "risk_level": "MEDIUM",               │
   │   "explanation": "Moderate risk...",    │
   │   "latency_ms": 1024.56                 │
   │ }                                       │
   └─────────────────────────────────────────┘
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
└──────────────────────────────────────────────────────────────┘

Layer 1: Network Security
┌─────────────────────────────────────────┐
│           AWS WAF                       │
│                                         │
│ • Rate Limiting: 2000 req/5min per IP   │
│ • SQL Injection Protection              │
│ • XSS Protection                        │
│ • Known Bad Inputs Blocking             │
│ • Geo-blocking (optional)               │
└─────────────────────────────────────────┘
                 │
                 ▼
Layer 2: API Security
┌─────────────────────────────────────────┐
│        API Gateway                      │
│                                         │
│ • HTTPS only (TLS 1.2+)                 │
│ • Request validation                    │
│ • Throttling (10,000 req/s)             │
│ • CORS configuration                    │
│ • CloudWatch logging                    │
└─────────────────────────────────────────┘
                 │
                 ▼
Layer 3: Compute Security
┌─────────────────────────────────────────┐
│          Lambda                         │
│                                         │
│ • IAM execution role (least privilege)  │
│ • Environment variables (encrypted)     │
│ • VPC isolation (optional)              │
│ • Resource-based policies               │
└─────────────────────────────────────────┘
                 │
                 ▼
Layer 4: Data Security
┌─────────────────────────────────────────┐
│    DynamoDB + S3 + Bedrock              │
│                                         │
│ • Encryption at rest (AES-256)          │
│ • Encryption in transit (TLS)           │
│ • IAM policies (least privilege)        │
│ • Audit logging (CloudTrail)            │
│ • Backup and recovery                   │
└─────────────────────────────────────────┘
```

---

## Cost Architecture

```
Monthly Cost Breakdown (1M requests/month)
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  API Gateway:        $1.00  (1M requests × $1/million)       │
│  Lambda:             $0.20  (1M requests × $0.20/million)    │
│  Lambda Compute:     $2.08  (1M × 100ms × 512MB)             │
│  Bedrock (Nova):     $5.00  (1M × 200 tokens × $0.0006/1K)   │
│  DynamoDB:           $1.25  (1M writes × $1.25/million)      │
│  WAF:                $5.00  (base) + $1.00 (1M requests)     │
│  CloudWatch:         $0.50  (logs + metrics)                 │
│  S3:                 $0.10  (storage)                        │
│  ─────────────────────────────────────────────────────────   │
│  TOTAL:             ~$16.13/month                            │
│                                                              │
│  vs EC2 Alternative: $78/month                               │
│  SAVINGS:            79% ($61.87/month)                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Cost Scaling (requests/month):
  10K:    ~$5/month   (mostly free tier)
  100K:   ~$8/month
  1M:     ~$16/month
  10M:    ~$150/month
```

---

## Monitoring Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   CloudWatch Monitoring                      │
└──────────────────────────────────────────────────────────────┘

Metrics Collected:
┌─────────────────────────────────────────┐
│ API Gateway:                            │
│ • Count (requests/min)                  │
│ • 4XXError, 5XXError                    │
│ • Latency (p50, p95, p99)               │
│ • IntegrationLatency                    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Lambda:                                 │
│ • Invocations                           │
│ • Errors                                │
│ • Duration                              │
│ • Throttles                             │
│ • ConcurrentExecutions                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DynamoDB:                               │
│ • ConsumedReadCapacityUnits             │
│ • ConsumedWriteCapacityUnits            │
│ • UserErrors                            │
│ • SystemErrors                          │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ WAF:                                    │
│ • AllowedRequests                       │
│ • BlockedRequests                       │
│ • CountedRequests                       │
│ • PassedRequests                        │
└─────────────────────────────────────────┘

Alarms Configured:
• High error rate (>5% for 5 minutes)
• High latency (>2s for 5 minutes)
• High throttle rate (>10 for 1 minute)
```

---

## Deployment Architecture

```
┌──────────────────────────────────────────────────────────────┐
│              Terraform Deployment Flow                       │
└──────────────────────────────────────────────────────────────┘

Developer Workstation / EC2
         │
         │ 1. terraform init
         ▼
┌─────────────────────────────────────────┐
│   Download Providers                    │
│   • AWS Provider                        │
│   • Archive Provider (for Lambda zip)   │
└─────────────────────────────────────────┘
         │
         │ 2. terraform plan
         ▼
┌─────────────────────────────────────────┐
│   Calculate Changes                     │
│   • Read current state                  │
│   • Compare with desired state          │
│   • Show diff                           │
└─────────────────────────────────────────┘
         │
         │ 3. terraform apply
         ▼
┌─────────────────────────────────────────┐
│   Create Resources (in order):          │
│   1. IAM roles                          │
│   2. DynamoDB table                     │
│   3. S3 bucket                          │
│   4. Lambda function                    │
│   5. API Gateway                        │
│   6. WAF                                │
│   7. CloudWatch logs                    │
│   8. SNS topic                          │
│   9. EventBridge rules                  │
└─────────────────────────────────────────┘
         │
         │ 4. Output values
         ▼
┌─────────────────────────────────────────┐
│   API Gateway URL                       │
│   Lambda Function ARN                   │
│   DynamoDB Table Name                   │
│   etc.                                  │
└─────────────────────────────────────────┘
```

---

## Visual Diagram Instructions

**To create a professional diagram:**

1. **Use draw.io (diagrams.net):**
   - Go to https://app.diagrams.net/
   - Choose "AWS Architecture" template
   - Drag and drop AWS service icons

2. **Key Components to Include:**
   - User/Client icon
   - AWS WAF icon
   - API Gateway icon
   - Lambda icon
   - Bedrock icon
   - DynamoDB icon
   - CloudWatch icon
   - SNS icon
   - EventBridge icon

3. **Arrows to Show:**
   - User → WAF → API Gateway → Lambda
   - Lambda → Bedrock (bidirectional)
   - Lambda → DynamoDB (write)
   - Lambda → EventBridge → SNS (conditional)
   - All services → CloudWatch (monitoring)

4. **Color Coding:**
   - Security layer: Red/Orange
   - Compute layer: Blue
   - Data layer: Green
   - Monitoring: Purple

5. **Export as:**
   - PNG (for README)
   - SVG (for documentation)
   - PDF (for presentations)

---

## Architecture Highlights for Interviews

**Key Points to Mention:**

1. **Serverless-First:**
   - "I chose serverless to minimize operational overhead and optimize costs"

2. **Security in Depth:**
   - "WAF provides the first line of defense, followed by API Gateway throttling and IAM policies"

3. **Cost Optimization:**
   - "Pay-per-request model reduces costs by 79% compared to always-on EC2 instances"

4. **Scalability:**
   - "Lambda automatically scales from 0 to 10,000 concurrent executions without configuration"

5. **Observability:**
   - "CloudWatch provides end-to-end visibility with logs, metrics, and alarms"

6. **AI Integration:**
   - "Bedrock's managed service eliminates ML infrastructure complexity while providing state-of-the-art models"
