# Architecture Decision Records (ADR)

This document explains the key architectural decisions made for the AWS Bedrock Fraud Detection system and the rationale behind them.

---

## ADR-001: Serverless Architecture (Lambda + API Gateway)

**Status:** Accepted  
**Date:** December 2025  
**Decision Makers:** Solutions Architect

### Context

Need to deploy a fraud detection API that:
- Handles variable traffic (10-10,000 requests/day)
- Requires high availability (99.9%+)
- Must be cost-effective for demo/POC
- Should minimize operational overhead

### Decision

Use **AWS Lambda + API Gateway** instead of EC2-based deployment.

### Rationale

**Why Lambda:**
1. **Cost Efficiency:** Pay-per-request model
   - First 1M requests/month: FREE
   - After: $0.20 per 1M requests
   - vs EC2: $30-78/month fixed cost
   - **Savings: 90%+ for variable workloads**

2. **Automatic Scaling:**
   - 0 to 10,000 concurrent executions
   - No configuration needed
   - Sub-second scale-up time
   - vs EC2 Auto Scaling: 2-5 minute scale-up

3. **High Availability:**
   - Built-in multi-AZ deployment
   - 99.99% SLA
   - No single point of failure
   - vs EC2: Requires manual HA setup

4. **Zero Operational Overhead:**
   - No server patching
   - No OS management
   - No capacity planning
   - vs EC2: Weekly maintenance windows

**Why API Gateway:**
1. **Purpose-Built for APIs:**
   - Built-in throttling (2000 req/s default)
   - Request/response transformation
   - API versioning support
   - vs ALB: Generic load balancer

2. **Security Features:**
   - WAF integration (added)
   - API keys and usage plans
   - CORS handling
   - Request validation

3. **Cost:**
   - $1 per million requests
   - vs ALB: $16/month + $0.008/LCU-hour

### Consequences

**Positive:**
- ✅ 90% cost reduction
- ✅ Instant scaling
- ✅ No maintenance burden
- ✅ Built-in monitoring (CloudWatch)

**Negative:**
- ⚠️ Cold start latency (500-1000ms first request)
- ⚠️ 15-minute max execution time (not an issue for API)
- ⚠️ Stateless (requires external storage)

**Mitigation:**
- Cold starts: Acceptable for fraud detection use case
- Execution time: API responses <2s, well within limit
- State: DynamoDB for transaction storage

### Alternatives Considered

**1. EC2 + Auto Scaling + ALB**
- ❌ Higher cost ($78/month)
- ❌ Complex setup (user_data scripts)
- ❌ Maintenance overhead
- ✅ No cold starts
- **Rejected:** Cost and complexity outweigh benefits

**2. ECS Fargate**
- ✅ No cold starts
- ✅ Container-based (good for complex apps)
- ❌ Higher cost than Lambda
- ❌ More complex than needed
- **Rejected:** Over-engineered for simple API

**3. App Runner**
- ✅ Simple deployment
- ✅ Auto-scaling
- ❌ Less mature service
- ❌ Limited AWS integration
- **Rejected:** Lambda more proven

---

## ADR-002: Amazon Bedrock (Nova Lite) for AI/ML

**Status:** Accepted  
**Date:** December 2025

### Context

Need AI/ML model for fraud detection that:
- Provides accurate risk scoring
- Doesn't require ML expertise to deploy
- Supports customization (RFT)
- Is cost-effective

### Decision

Use **Amazon Bedrock with Nova Lite model** and Reinforcement Fine-Tuning (RFT).

### Rationale

**Why Bedrock:**
1. **Managed Service:**
   - No model hosting infrastructure
   - No GPU management
   - Automatic scaling
   - vs SageMaker: Requires endpoint management

2. **Multiple Models:**
   - Access to Claude, Nova, Titan
   - Easy model switching
   - No vendor lock-in

3. **RFT Support:**
   - 66% accuracy improvement over base model
   - No labeled data required
   - Automated training workflow

**Why Nova Lite:**
1. **Cost:**
   - $0.00006 per 1K input tokens
   - $0.00024 per 1K output tokens
   - vs Claude: 10x more expensive

2. **Performance:**
   - <100ms inference latency
   - Sufficient for fraud detection
   - vs Larger models: Overkill for this use case

3. **RFT Compatible:**
   - Supports Reinforcement Fine-Tuning
   - vs Claude: RFT not available

### Consequences

**Positive:**
- ✅ No ML infrastructure management
- ✅ 66% accuracy improvement with RFT
- ✅ Cost-effective ($5-10/month)
- ✅ Easy to switch models if needed

**Negative:**
- ⚠️ Vendor lock-in to AWS
- ⚠️ Content filters (mitigated with prompt engineering)
- ⚠️ Model updates controlled by AWS

### Alternatives Considered

**1. SageMaker + Custom Model**
- ✅ Full control
- ✅ Any ML framework
- ❌ Complex setup (endpoints, scaling)
- ❌ Higher cost ($50-100/month)
- ❌ Requires ML expertise
- **Rejected:** Over-engineered

**2. OpenAI API**
- ✅ High accuracy
- ✅ Easy integration
- ❌ External dependency
- ❌ Higher cost
- ❌ Data leaves AWS
- **Rejected:** Security and cost concerns

**3. Rule-Based System**
- ✅ Simple
- ✅ Predictable
- ❌ Low accuracy
- ❌ Hard to maintain
- ❌ Can't adapt to new patterns
- **Rejected:** Doesn't showcase AI/ML skills

---

## ADR-003: DynamoDB for Transaction Storage

**Status:** Accepted  
**Date:** December 2025

### Context

Need to store transaction audit logs for:
- Compliance and auditing
- Historical analysis
- Fraud pattern detection

### Decision

Use **DynamoDB with on-demand pricing**.

### Rationale

**Why DynamoDB:**
1. **Serverless:**
   - No server management
   - Automatic scaling
   - Matches Lambda architecture

2. **Performance:**
   - Single-digit millisecond latency
   - Unlimited throughput
   - vs RDS: Requires connection pooling

3. **Cost (On-Demand):**
   - $1.25 per million write requests
   - $0.25 per million read requests
   - No idle cost
   - vs Provisioned: Pay for unused capacity

4. **Integration:**
   - Native AWS SDK support
   - DynamoDB Streams for real-time processing
   - Easy Lambda integration

### Consequences

**Positive:**
- ✅ No database management
- ✅ Automatic scaling
- ✅ Cost-effective for variable workload
- ✅ High availability (multi-AZ)

**Negative:**
- ⚠️ NoSQL limitations (no complex queries)
- ⚠️ Schema design important upfront
- ⚠️ Expensive for high-volume reads

**Mitigation:**
- Simple access patterns (get by transaction_id)
- Infrequent reads (write-heavy workload)

### Alternatives Considered

**1. RDS (PostgreSQL/MySQL)**
- ✅ SQL queries
- ✅ ACID transactions
- ❌ Requires server management
- ❌ Fixed cost ($15-30/month)
- ❌ Connection pooling complexity with Lambda
- **Rejected:** Over-engineered for simple key-value storage

**2. S3**
- ✅ Cheapest storage
- ✅ Unlimited capacity
- ❌ High latency (100-200ms)
- ❌ No real-time queries
- ❌ Not suitable for transactional data
- **Rejected:** Wrong tool for the job

**3. ElastiCache (Redis)**
- ✅ Ultra-fast (<1ms)
- ✅ Rich data structures
- ❌ In-memory only (data loss risk)
- ❌ Fixed cost ($15-50/month)
- ❌ Requires VPC setup
- **Rejected:** Overkill and not durable

---

## ADR-004: AWS WAF for API Protection

**Status:** Accepted  
**Date:** December 2025

### Context

API Gateway is publicly accessible and needs protection against:
- DDoS attacks
- SQL injection attempts
- Common web exploits
- Excessive request rates

### Decision

Add **AWS WAF** with managed rule sets to API Gateway.

### Rationale

**Why WAF:**
1. **Security:**
   - Rate limiting (2000 req/s per IP)
   - AWS Managed Rules (OWASP Top 10)
   - Known bad inputs blocking
   - vs No WAF: Vulnerable to attacks

2. **Cost:**
   - $5/month base + $1 per million requests
   - vs DDoS damage: Potentially thousands
   - Insurance against abuse

3. **Compliance:**
   - Shows security awareness
   - Required for production deployments
   - Audit trail in CloudWatch

**Rules Implemented:**
1. **Rate Limiting:** 2000 requests/5min per IP
2. **Common Rule Set:** SQL injection, XSS protection
3. **Known Bad Inputs:** Malformed requests

### Consequences

**Positive:**
- ✅ Protection against common attacks
- ✅ Rate limiting prevents abuse
- ✅ CloudWatch metrics for monitoring
- ✅ Shows security best practices

**Negative:**
- ⚠️ Additional cost ($5-10/month)
- ⚠️ Potential false positives
- ⚠️ Adds latency (~5-10ms)

**Mitigation:**
- Cost: Acceptable for production-grade security
- False positives: Tunable rules
- Latency: Negligible for fraud detection use case

### Alternatives Considered

**1. No WAF**
- ✅ Zero cost
- ✅ No latency
- ❌ Vulnerable to attacks
- ❌ No rate limiting
- **Rejected:** Unacceptable security risk

**2. API Gateway Throttling Only**
- ✅ Built-in feature
- ✅ No extra cost
- ❌ No attack protection
- ❌ Account-level limits only
- **Rejected:** Insufficient protection

**3. CloudFront + WAF**
- ✅ CDN benefits
- ✅ Global edge locations
- ❌ More complex setup
- ❌ Higher cost
- ❌ Overkill for single-region API
- **Rejected:** Over-engineered

---

## ADR-005: Terraform for Infrastructure as Code

**Status:** Accepted  
**Date:** December 2025

### Context

Need to deploy and manage AWS infrastructure in a:
- Repeatable way
- Version-controlled manner
- Auditable process

### Decision

Use **Terraform** for all infrastructure provisioning.

### Rationale

**Why Terraform:**
1. **Multi-Cloud:**
   - Not locked to AWS
   - Can add Azure/GCP later
   - vs CloudFormation: AWS-only

2. **State Management:**
   - Tracks resource state
   - Detects drift
   - Enables collaboration

3. **Modularity:**
   - Reusable modules
   - Clean separation (lambda.tf, waf.tf, etc.)
   - Easy to understand

4. **Community:**
   - Large ecosystem
   - Well-documented
   - Industry standard

### Consequences

**Positive:**
- ✅ Infrastructure as code
- ✅ Version controlled
- ✅ Repeatable deployments
- ✅ Easy to destroy/recreate

**Negative:**
- ⚠️ State file management
- ⚠️ Learning curve
- ⚠️ Potential state drift

**Mitigation:**
- State: Local for demo, S3 for production
- Learning: Well-documented
- Drift: Regular `terraform plan` checks

### Alternatives Considered

**1. AWS CloudFormation**
- ✅ Native AWS integration
- ✅ No state file
- ❌ AWS-only
- ❌ Verbose YAML
- ❌ Slower deployments
- **Rejected:** Less flexible

**2. AWS CDK**
- ✅ Programming language (Python/TypeScript)
- ✅ Type safety
- ❌ Generates CloudFormation (slow)
- ❌ More complex
- **Rejected:** Overkill for simple infrastructure

**3. Manual Console**
- ✅ Visual interface
- ✅ No learning curve
- ❌ Not repeatable
- ❌ No version control
- ❌ Error-prone
- **Rejected:** Not professional

---

## Summary of Key Decisions

| Decision | Choice | Key Benefit |
|----------|--------|-------------|
| **Compute** | Lambda | 90% cost savings |
| **API** | API Gateway | Purpose-built for APIs |
| **AI/ML** | Bedrock (Nova Lite) | Managed, RFT support |
| **Storage** | DynamoDB | Serverless, auto-scaling |
| **Security** | WAF | Attack protection |
| **IaC** | Terraform | Multi-cloud, modular |

---

## Trade-offs Accepted

1. **Cold Starts:** Acceptable for fraud detection (not real-time trading)
2. **Vendor Lock-in:** AWS-specific, but easy to migrate if needed
3. **NoSQL Limitations:** Simple queries sufficient for this use case
4. **WAF Cost:** $5-10/month acceptable for security

---

## Future Considerations

**If scaling to production:**

1. **Multi-Region:**
   - Add us-west-2 for disaster recovery
   - Route53 for failover
   - DynamoDB Global Tables

2. **Enhanced Monitoring:**
   - X-Ray for distributed tracing
   - Custom CloudWatch dashboards
   - PagerDuty integration

3. **CI/CD Pipeline:**
   - GitHub Actions for automated deployment
   - Automated testing
   - Blue/green deployments

4. **Data Analytics:**
   - Kinesis for real-time streaming
   - S3 + Athena for historical analysis
   - QuickSight for dashboards

5. **Advanced Security:**
   - Secrets Manager for API keys
   - KMS for encryption at rest
   - VPC endpoints for private connectivity

---

## Conclusion

This architecture prioritizes:
1. **Cost efficiency** (90% savings over EC2)
2. **Simplicity** (serverless = less to manage)
3. **Scalability** (automatic, instant)
4. **Security** (WAF, IAM, CloudWatch)

The decisions reflect **AWS Solutions Architect best practices**: right-sized solutions, cost optimization, and operational excellence.
