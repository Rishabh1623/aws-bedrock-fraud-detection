# Getting Started - Your First Deployment

Welcome! This guide will walk you through deploying your fraud detection system step-by-step.

## 📋 What You'll Build

By the end of this guide, you'll have:
- ✅ A production-grade fraud detection API running on AWS
- ✅ Multi-AZ architecture with auto-scaling
- ✅ Real-time transaction scoring with <100ms latency
- ✅ Complete monitoring and alerting setup
- ✅ A portfolio project to showcase in interviews

**Time Required:** 45-60 minutes  
**Cost:** ~$2-3 for testing (can be destroyed after)

---

## Step 1: Prerequisites (15 minutes)

### 1.1 Create AWS Account

If you don't have an AWS account:
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the signup process
4. Add a credit card (required, but you'll use free tier)
5. Verify your identity

### 1.2 Install Required Tools

**Windows:**
```powershell
# Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install awscli terraform python nodejs git -y
```

**Mac:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install awscli terraform python@3.11 node git
```

**Linux (Ubuntu/Debian):**
```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Python, Node, Git
sudo apt install python3.11 python3-pip nodejs npm git -y
```

### 1.3 Verify Installations

```bash
aws --version        # Should show: aws-cli/2.x
terraform --version  # Should show: Terraform v1.x
python --version     # Should show: Python 3.11+
node --version       # Should show: v18+
git --version        # Should show: git version 2.x
```

---

## Step 2: AWS Setup (10 minutes)

### 2.1 Create IAM User

1. Log into [AWS Console](https://console.aws.amazon.com)
2. Go to **IAM** → **Users** → **Create user**
3. Username: `terraform-user`
4. Check "Provide user access to AWS Management Console" (optional)
5. Click **Next**
6. Select "Attach policies directly"
7. Add: `AdministratorAccess` (for learning; use least privilege in production)
8. Click **Create user**

### 2.2 Create Access Keys

1. Click on the user you just created
2. Go to **Security credentials** tab
3. Scroll to **Access keys**
4. Click **Create access key**
5. Select "Command Line Interface (CLI)"
6. Check the confirmation box
7. Click **Create access key**
8. **IMPORTANT:** Download the CSV or copy the keys (you won't see them again!)

### 2.3 Configure AWS CLI

```bash
aws configure

# Enter when prompted:
AWS Access Key ID: [paste your access key]
AWS Secret Access Key: [paste your secret key]
Default region name: us-east-1
Default output format: json
```

**Test it works:**
```bash
aws sts get-caller-identity
```

You should see your account ID and user ARN.

### 2.4 Enable Amazon Bedrock

1. Go to [Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Make sure you're in **us-east-1** region (top right)
3. Click **Model access** in left sidebar
4. Click **Enable specific models**
5. Find **Claude 3 Haiku** by Anthropic
6. Click **Enable**
7. Click **Submit**
8. Wait for status to show "Access granted" (usually instant)

**Verify:**
```bash
aws bedrock list-foundation-models --region us-east-1 | grep -i haiku
```

---

## Step 3: Deploy Infrastructure (15 minutes)

### 3.1 Clone Repository

```bash
# Clone the project
git clone https://github.com/Rishabh1623/aws-bedrock-fraud-detection.git

# Navigate into it
cd aws-bedrock-fraud-detection

# Verify structure
ls -la
```

You should see: `infrastructure/`, `api/`, `model/`, `docs/`, etc.

### 3.2 Configure Deployment

```bash
cd infrastructure

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the file (use your preferred editor)
nano terraform.tfvars
# or
code terraform.tfvars
# or
notepad terraform.tfvars
```

**Update these values:**

```hcl
aws_region      = "us-east-1"
project_name    = "fraud-detection-rft"
environment     = "dev"
owner_email     = "YOUR_EMAIL@example.com"  # ← Change this

# Get your IP address first: curl ifconfig.me
allowed_ssh_cidr = ["YOUR_IP/32"]  # ← Change this

# For testing, use smaller/cheaper resources
ec2_instance_type = "t3.small"     # Cheaper than t3.medium
enable_multi_az   = false          # Single AZ for testing
enable_waf        = false          # Not needed for testing
```

### 3.3 Initialize Terraform

```bash
# Initialize (downloads AWS provider)
terraform init
```

You should see: "Terraform has been successfully initialized!"

### 3.4 Preview Changes

```bash
# See what will be created
terraform plan
```

Review the output. You should see ~30-40 resources to be created:
- VPC, subnets, route tables
- ALB, target groups
- Auto Scaling Group, Launch Template
- DynamoDB table
- S3 buckets
- CloudWatch alarms
- IAM roles

### 3.5 Deploy!

```bash
# Deploy everything
terraform apply

# Type 'yes' when prompted
```

**⏱️ This takes 10-15 minutes.** Go grab a coffee! ☕

You'll see resources being created one by one. At the end, you'll see:

```
Apply complete! Resources: 35 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "fraud-detection-rft-alb-1234567890.us-east-1.elb.amazonaws.com"
api_endpoint = "http://fraud-detection-rft-alb-1234567890.us-east-1.elb.amazonaws.com/score"
...
```

**💾 SAVE THE `alb_dns_name` OUTPUT!** You'll need it for testing.

---

## Step 4: Wait for System to Boot (5-10 minutes)

EC2 instances need time to:
1. Boot up
2. Install dependencies
3. Start the API application
4. Pass health checks

### 4.1 Check Instance Status

```bash
# Check if instances are running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=fraud-detection-rft-api-server" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]" \
  --output table
```

### 4.2 Check Target Health

```bash
# Check if ALB sees instances as healthy
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names fraud-detection-rft-api-tg \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)
```

Wait until you see: `"State": "healthy"`

---

## Step 5: Test Your API (5 minutes)

### 5.1 Get Your API Endpoint

```bash
cd infrastructure
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Your API: http://$ALB_DNS"
```

### 5.2 Test Health Check

```bash
curl http://$ALB_DNS/health
```

**Expected response:**
```json
{"status":"healthy","timestamp":"2024-12-03T12:34:56.789Z"}
```

If you get an error, wait a few more minutes and try again.

### 5.3 Test Fraud Detection

**Test 1: Normal Transaction (Low Risk)**
```bash
curl -X POST http://$ALB_DNS/score \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "transaction_id": "TEST001",
      "amount": 45.99,
      "merchant": "Amazon",
      "location": "New York",
      "card_present": true,
      "recent_transaction_count": 2
    }
  }'
```

**Expected:** `"risk_level":"LOW"` with risk_score around 0.1-0.3

**Test 2: Suspicious Transaction (High Risk)**
```bash
curl -X POST http://$ALB_DNS/score \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "transaction_id": "TEST002",
      "amount": 2500.00,
      "merchant": "UNKNOWN_MERCHANT",
      "location": "Foreign Country",
      "card_present": false,
      "recent_transaction_count": 15
    }
  }'
```

**Expected:** `"risk_level":"HIGH"` with risk_score around 0.8-0.95

### 5.4 Run Automated Tests

```bash
cd ..
bash scripts/test_api.sh http://$ALB_DNS
```

You should see all tests pass with ✓ marks.

---

## Step 6: Explore Your Infrastructure (5 minutes)

### 6.1 AWS Console Tour

Open [AWS Console](https://console.aws.amazon.com) and explore:

1. **EC2 Dashboard**
   - See your running instances
   - Check CPU and network metrics

2. **Load Balancers**
   - View your ALB
   - Check target health
   - See request metrics

3. **VPC**
   - See your custom VPC
   - View subnets (public and private)
   - Check route tables

4. **DynamoDB**
   - Open `fraud-detection-rft-transactions` table
   - View transaction logs
   - See items being added

5. **CloudWatch**
   - View logs: `/aws/ec2/fraud-detection-rft`
   - Check metrics dashboard
   - See alarms

### 6.2 View Application Logs

```bash
# Stream live logs
aws logs tail /aws/ec2/fraud-detection-rft --follow

# View recent logs
aws logs tail /aws/ec2/fraud-detection-rft --since 10m
```

### 6.3 Check DynamoDB Data

```bash
# Count transactions
aws dynamodb scan \
  --table-name fraud-detection-rft-transactions \
  --select COUNT

# View recent transactions
aws dynamodb scan \
  --table-name fraud-detection-rft-transactions \
  --limit 5
```

---

## Step 7: Cleanup (5 minutes)

**IMPORTANT:** To avoid ongoing charges, destroy resources when done testing.

```bash
cd infrastructure

# Destroy everything
terraform destroy

# Type 'yes' when prompted
```

This removes all AWS resources and stops billing.

---

## 🎉 Congratulations!

You've successfully:
- ✅ Deployed a production-grade AWS architecture
- ✅ Created a multi-AZ, auto-scaling system
- ✅ Integrated Amazon Bedrock for AI/ML
- ✅ Built a real-time fraud detection API
- ✅ Gained hands-on AWS experience

## 📚 Next Steps

1. **Add to Resume**
   - "Architected production-grade fraud detection system on AWS with Bedrock RFT"
   - "Deployed multi-AZ infrastructure with Terraform, achieving <100ms latency"

2. **Enhance Your Project**
   - Add custom training data
   - Train your own RFT model
   - Deploy the React dashboard
   - Add more test cases

3. **Study for Interviews**
   - Read [docs/INTERVIEW_GUIDE.md](docs/INTERVIEW_GUIDE.md)
   - Review [docs/AWS_SA_PORTFOLIO.md](docs/AWS_SA_PORTFOLIO.md)
   - Practice explaining the architecture

4. **Share Your Work**
   - Add screenshots to README
   - Write a blog post
   - Share on LinkedIn
   - Add to your portfolio

## 🆘 Need Help?

- 📖 [Full README](README.md)
- 🏗️ [Architecture Guide](docs/ARCHITECTURE.md)
- 💬 [GitHub Issues](https://github.com/Rishabh1623/aws-bedrock-fraud-detection/issues)
- 📧 Email: rishabh@example.com

**Great job!** You're now ready to showcase this project in AWS Solutions Architect interviews! 🚀
