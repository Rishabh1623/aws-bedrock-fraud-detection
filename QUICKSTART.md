# Quick Start Guide - 15 Minutes to Running System

This guide gets you from zero to a working fraud detection system in ~15 minutes.

## Prerequisites (5 minutes)

1. **AWS Account** - [Sign up here](https://aws.amazon.com/free/) if you don't have one
2. **Install AWS CLI** - [Download](https://aws.amazon.com/cli/)
3. **Install Terraform** - [Download](https://www.terraform.io/downloads)
4. **Install Python 3.11+** - [Download](https://www.python.org/downloads/)

## Step-by-Step (10 minutes)

### 1. Configure AWS (2 minutes)

```bash
# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# Verify
aws sts get-caller-identity
```

### 2. Enable Bedrock (1 minute)

```bash
# Open Bedrock console
open https://console.aws.amazon.com/bedrock/

# Click "Model access" → Enable "Claude 3 Haiku" → Submit
```

### 3. Clone and Deploy (5 minutes)

```bash
# Clone repo
git clone https://github.com/Rishabh1623/aws-bedrock-fraud-detection.git
cd aws-bedrock-fraud-detection

# Configure
cd infrastructure
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars - change:
# - owner_email to your email
# - allowed_ssh_cidr to your IP (get it: curl ifconfig.me)

# Deploy
terraform init
terraform apply -auto-approve

# ⏱️ Wait 5-10 minutes for deployment
```

### 4. Test API (2 minutes)

```bash
# Get API endpoint
ALB_DNS=$(terraform output -raw alb_dns_name)

# Wait for health check (may take 5 minutes)
while ! curl -s http://$ALB_DNS/health | grep -q "healthy"; do
  echo "Waiting for API to be ready..."
  sleep 30
done

# Test fraud detection
curl -X POST http://$ALB_DNS/score \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "transaction_id": "TEST123",
      "amount": 2500.00,
      "merchant": "UNKNOWN_MERCHANT",
      "location": "Foreign Country",
      "card_present": false,
      "recent_transaction_count": 15
    }
  }'

# Should return: {"transaction_id":"TEST123","risk_score":0.85,"risk_level":"HIGH",...}
```

## ✅ Success!

You now have:
- ✅ Multi-AZ VPC with public/private subnets
- ✅ Application Load Balancer
- ✅ Auto Scaling EC2 instances
- ✅ DynamoDB for transaction logs
- ✅ CloudWatch monitoring
- ✅ Working fraud detection API

## Next Steps

1. **View Infrastructure**
   - AWS Console → EC2 → See your instances
   - AWS Console → Load Balancers → See your ALB
   - AWS Console → VPC → See your network

2. **Generate Training Data**
   ```bash
   cd ../data
   python generate_sample_data.py
   ```

3. **View Logs**
   ```bash
   aws logs tail /aws/ec2/fraud-detection-rft --follow
   ```

4. **Check Costs**
   ```bash
   # View current month costs
   aws ce get-cost-and-usage \
     --time-period Start=2024-12-01,End=2024-12-31 \
     --granularity MONTHLY \
     --metrics BlendedCost
   ```

5. **Cleanup When Done**
   ```bash
   cd infrastructure
   terraform destroy -auto-approve
   ```

## Troubleshooting

**API not responding?**
- Wait 10 minutes for EC2 instances to fully boot
- Check target health: `aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names fraud-detection-rft-api-tg --query "TargetGroups[0].TargetGroupArn" --output text)`

**Terraform errors?**
- Make sure Bedrock access is enabled
- Check your AWS credentials: `aws sts get-caller-identity`
- Verify region supports Bedrock: use us-east-1 or us-west-2

**High costs?**
- Destroy resources when not in use: `terraform destroy`
- Use t3.small instances for testing (cheaper)
- Set enable_multi_az = false in terraform.tfvars

## Need Help?

- 📖 Full guide: [README.md](README.md)
- 🏗️ Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 💬 Issues: [GitHub Issues](https://github.com/Rishabh1623/aws-bedrock-fraud-detection/issues)

Happy building! 🚀
