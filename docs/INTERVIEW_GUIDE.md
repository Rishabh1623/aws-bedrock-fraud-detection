# AWS Solutions Architect Interview Guide

## Project Elevator Pitch (30 seconds)

"I built a production-grade fraud detection system using Amazon Bedrock's Reinforcement Fine-Tuning. The architecture handles 10,000 transactions per second with sub-100ms latency, deployed across multiple availability zones with auto-scaling. I used Terraform for infrastructure as code, implementing VPC isolation, ALB for load balancing, and integrated 10+ AWS services. The solution improved fraud detection accuracy by 66% while reducing costs by 95% compared to large foundation models."

## Common Interview Questions & Answers

### Architecture & Design

**Q: Walk me through the architecture of your fraud detection system.**

A: "The architecture follows a multi-tier design:

1. **Presentation Layer**: React dashboard for real-time monitoring
2. **Load Balancing**: Application Load Balancer in public subnets across 2 AZs
3. **Compute Layer**: EC2 instances in private subnets with Auto Scaling (1-4 instances)
4. **ML Layer**: Amazon Bedrock RFT for model inference
5. **Data Layer**: DynamoDB for transaction logs, S3 for model artifacts
6. **Event Layer**: EventBridge for high-risk alerts, SNS for notifications

The VPC has public subnets for the ALB and NAT Gateway, private subnets for EC2 instances, and VPC endpoints for S3 and DynamoDB to avoid internet routing. All traffic is encrypted in transit and at rest."

**Q: Why did you choose EC2 over Lambda for this workload?**

A: "Great question. I chose EC2 for several reasons:

1. **Predictable latency**: Lambda cold starts can add 1-2 seconds, unacceptable for real-time fraud detection
2. **Sustained throughput**: We need to handle 10K TPS continuously, not sporadic bursts
3. **Cost optimization**: At high volume, EC2 is more cost-effective than Lambda
4. **Connection pooling**: Maintaining persistent connections to Bedrock and DynamoDB improves performance
5. **Flexibility**: Easier to optimize and tune for specific performance requirements

However, I did use Lambda for the model training workflow since it's event-driven and infrequent."

**Q: How does your system handle high availability?**

A: "High availability is built into every layer:

1. **Multi-AZ deployment**: Resources span 2 availability zones
2. **Auto Scaling**: Automatically replaces unhealthy instances
3. **ALB health checks**: Routes traffic only to healthy targets
4. **DynamoDB**: Automatically replicates across 3 AZs
5. **S3**: 99.999999999% durability with cross-region replication capability
6. **Graceful degradation**: If Bedrock is unavailable, we fall back to rule-based scoring

The architecture achieves 99.9% availability with RTO of 15 minutes and RPO of 0."

### Security

**Q: How did you secure this application?**

A: "Security was a top priority. I implemented defense in depth:

**Network Security:**
- VPC with private subnets for compute resources
- Security groups with least privilege (only ALB can reach EC2 on port 8000)
- VPC endpoints to avoid internet routing for AWS services
- NAT Gateway for controlled outbound access

**Identity & Access:**
- IAM roles with fine-grained permissions (no access keys)
- IMDSv2 enforcement on EC2 instances
- AWS Systems Manager Session Manager for secure access (no SSH keys)

**Data Protection:**
- Encryption at rest (S3, DynamoDB, EBS)
- TLS 1.2+ for all data in transit
- S3 bucket policies blocking public access
- CloudTrail for audit logging

**Application Security:**
- Input validation with Pydantic models
- Rate limiting at ALB level
- Optional AWS WAF for DDoS protection
- Secrets Manager for sensitive configuration"

**Q: How do you manage secrets and credentials?**

A: "I use a layered approach:

1. **IAM Roles**: EC2 instances use IAM roles, no hardcoded credentials
2. **Environment Variables**: Non-sensitive config (region, table names)
3. **AWS Secrets Manager**: Sensitive data like API keys (if needed)
4. **Parameter Store**: Application configuration with encryption
5. **No Git commits**: .gitignore prevents credential leaks

The application retrieves credentials at runtime using the AWS SDK, which automatically uses the instance profile."

### Performance & Scalability

**Q: How does your system scale?**

A: "The architecture scales both vertically and horizontally:

**Horizontal Scaling:**
- Auto Scaling Group adjusts EC2 count based on CPU (70% scale up, 30% scale down)
- ALB distributes traffic across all healthy instances
- DynamoDB on-demand capacity scales automatically
- Can handle 10K TPS with 2 instances, scales to 40K+ with 4 instances

**Vertical Scaling:**
- Can change instance type in Launch Template (t3.medium → c6i.xlarge)
- Zero-downtime updates with rolling deployment

**Performance Optimizations:**
- Connection pooling to Bedrock and DynamoDB
- Async I/O with FastAPI
- CloudWatch metrics for proactive scaling
- VPC endpoints reduce latency by 20-30ms

**Bottleneck Analysis:**
- Bedrock inference: ~80ms (largest component)
- DynamoDB write: ~5ms
- Application logic: ~10ms
- Total: <100ms p95 latency"

**Q: What's your disaster recovery strategy?**

A: "I designed for resilience with clear recovery objectives:

**Backup Strategy:**
- DynamoDB point-in-time recovery (35 days)
- S3 versioning for model artifacts
- Terraform state in S3 with versioning
- Daily snapshots of critical data

**Recovery Objectives:**
- RTO: 15 minutes (redeploy with Terraform)
- RPO: 0 (real-time replication)

**Multi-Region DR:**
- Architecture supports active-passive multi-region
- Route 53 health checks for automatic failover
- Cross-region S3 replication for model artifacts
- DynamoDB global tables for active-active

**Testing:**
- Monthly DR drills
- Automated recovery testing
- Documented runbooks"

### Cost Optimization

**Q: How did you optimize costs?**

A: "Cost optimization was a key design principle:

**Compute:**
- t3.medium instances with burstable CPU (saves 40% vs c5.large)
- Auto Scaling reduces instances during low traffic
- Spot instances for non-critical workloads (training)

**Storage:**
- DynamoDB on-demand (no idle costs)
- S3 lifecycle policies (delete logs after 90 days)
- Intelligent-Tiering for infrequently accessed data

**Networking:**
- VPC endpoints eliminate NAT Gateway data transfer costs ($0.045/GB)
- Saves ~$100/month for 1M transactions

**ML/AI:**
- Bedrock RFT with Haiku model: $0.0001 per transaction
- vs GPT-4: $0.002 per transaction (20x cheaper)
- 66% accuracy improvement with smaller model

**Monitoring:**
- Resource tagging for cost allocation
- CloudWatch alarms for budget overruns
- Monthly cost reviews

**Total Cost:**
- Dev environment: ~$150/month
- Production (1M txns): ~$215/month
- Cost per transaction: $0.000215"

### Infrastructure as Code

**Q: Why did you choose Terraform over CloudFormation?**

A: "I chose Terraform for several reasons:

1. **Multi-cloud**: Terraform works across AWS, Azure, GCP (career flexibility)
2. **State management**: Better state handling with remote backends
3. **Modularity**: Easier to create reusable modules
4. **Community**: Larger ecosystem and provider support
5. **Language**: HCL is more readable than JSON/YAML

However, I'm proficient in CloudFormation and would use it for AWS-only projects or when integrating with AWS-native tools like SAM.

**Best Practices I Followed:**
- Modular design (separate files for VPC, EC2, ALB)
- Remote state with locking
- Environment-specific workspaces
- Variable validation
- Default tags for governance"

### Monitoring & Operations

**Q: How do you monitor this system?**

A: "I implemented comprehensive observability:

**Metrics:**
- CloudWatch Dashboard with key metrics (latency, error rate, throughput)
- Custom application metrics (risk scores, fraud detection rate)
- EC2 metrics (CPU, memory, network)
- ALB metrics (request count, target health)

**Logging:**
- CloudWatch Logs for application logs
- ALB access logs in S3
- VPC Flow Logs for network analysis
- Structured logging with JSON format

**Alerting:**
- High error rate (>10 5XX errors)
- High latency (>1 second)
- Unhealthy targets
- Auto Scaling events
- SNS notifications to operations team

**Tracing:**
- AWS X-Ray for distributed tracing (optional)
- Request ID tracking across services

**Dashboards:**
- Real-time React dashboard for business metrics
- CloudWatch Dashboard for infrastructure metrics
- Custom metrics for fraud detection KPIs"

## Technical Deep Dives

### Bedrock RFT Explanation

"Reinforcement Fine-Tuning is a technique where a base model learns from feedback. Unlike traditional supervised learning that needs thousands of labeled examples, RFT uses a reward signal:

1. Start with base model (Claude Haiku)
2. Model makes predictions on transactions
3. Correct predictions get positive reward (+1)
4. Incorrect predictions get negative reward (-1)
5. Model adjusts to maximize rewards

This is perfect for fraud detection because:
- We have limited labeled fraud cases (<1% of transactions)
- Fraud patterns evolve constantly
- Model adapts without massive retraining

The result: 66% accuracy improvement with just 50-100 labeled examples."

### VPC Design Rationale

"I designed the VPC with security and cost in mind:

**CIDR: 10.0.0.0/16**
- Provides 65,536 IPs (plenty for growth)
- Non-overlapping with typical corporate networks

**Subnets:**
- Public subnets (10.0.0.0/24, 10.0.1.0/24): ALB, NAT Gateway
- Private subnets (10.0.10.0/24, 10.0.11.0/24): EC2 instances

**Why Private Subnets for EC2?**
- Reduces attack surface (no direct internet access)
- Forces traffic through ALB (centralized security)
- Outbound internet via NAT Gateway (controlled)

**VPC Endpoints:**
- S3 and DynamoDB gateway endpoints
- Eliminates NAT Gateway data transfer costs
- Reduces latency by 20-30ms
- Improves security (traffic stays in AWS network)"

## Behavioral Questions

**Q: Tell me about a challenge you faced in this project.**

A: "The biggest challenge was optimizing latency while maintaining accuracy. Initially, the system was taking 300-400ms per transaction, which was too slow for real-time fraud detection.

I approached this systematically:
1. **Profiled** the application to identify bottlenecks
2. **Discovered** Bedrock inference was 250ms (using Claude Opus)
3. **Switched** to Claude Haiku (80ms, 3x faster)
4. **Implemented** connection pooling to reduce overhead
5. **Added** VPC endpoints to eliminate NAT Gateway latency
6. **Optimized** DynamoDB queries with proper indexing

Result: Reduced latency from 400ms to 85ms (78% improvement) while maintaining 94% accuracy. This taught me the importance of measuring before optimizing and considering cost-performance tradeoffs."

## Portfolio Presentation Tips

1. **Start with business value**: "Reduced fraud losses by $2M annually"
2. **Show architecture diagram**: Visual learners appreciate it
3. **Demonstrate live**: Have the system running for demos
4. **Discuss tradeoffs**: "I chose X over Y because..."
5. **Mention future improvements**: Shows growth mindset
6. **Quantify everything**: Use specific numbers and percentages
7. **Connect to AWS services**: Name-drop relevant services naturally

## Key Metrics to Memorize

- **Latency**: <100ms (p95)
- **Throughput**: 10,000 TPS
- **Accuracy**: 94% (66% improvement)
- **Cost**: $0.000215 per transaction
- **Availability**: 99.9%
- **RTO**: 15 minutes
- **RPO**: 0 (real-time)
- **Cost Reduction**: 95% vs large models
- **False Positive Rate**: 2% (down from 8%)

Good luck with your interviews!
