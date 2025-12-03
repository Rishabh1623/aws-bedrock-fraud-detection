# Deploy from Ubuntu EC2 Instance

This guide shows you how to deploy the fraud detection system from an Ubuntu EC2 instance (your control/bastion instance).

## 🎯 Architecture Overview

You'll use one EC2 instance as your **deployment/management server** to create the fraud detection infrastructure:

```
Your Ubuntu EC2 (Deployment Server)
    ↓ (runs Terraform)
    ↓
Creates: VPC, ALB, Auto Scaling Group, DynamoDB, etc.
```

**Benefits:**
- ✅ No need to install tools on your local machine
- ✅ Faster AWS API calls (same region)
- ✅ Can leave deployment running and disconnect
- ✅ Consistent environment for all deployments

---

## Step 1: Launch Ubuntu EC2 Instance (5 minutes)

### 1.1 Create EC2 Instance via AWS Console

1. Go to [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Click **Launch Instance**
3. Configure:
   - **Name**: `terraform-deployment-server`
   - **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type**: `t2.micro` or `t3.micro` (free tier)
   - **Key pair**: Create new or use existing
   - **Network**: Default VPC is fine
   - **Security group**: Allow SSH (port 22) from your IP
   - **Storage**: 8 GB (default is fine)
4. Click **Launch Instance**
5. Wait 2-3 minutes for instance to start

### 1.2 Connect to Your Instance

```bash
# Download your key pair (if new)
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# Or use EC2 Instance Connect (browser-based)
# EC2 Console → Select instance → Connect → EC2 Instance Connect
```

---

## Step 2: Install Required Tools (10 minutes)

Once connected to your Ubuntu EC2 instance, run these commands:

### 2.1 Update System

```bash
# Update package list
sudo apt update

# Upgrade existing packages (optional but recommended)
sudo apt upgrade -y
```

### 2.2 Install AWS CLI

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
# Should show: aws-cli/2.x.x
```

### 2.3 Install Terraform

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update
sudo apt install terraform -y

# Verify installation
terraform --version
# Should show: Terraform v1.x.x
```

### 2.4 Install Python 3 and Pip

```bash
# Install Python 3 (usually pre-installed on Ubuntu)
sudo apt install python3 python3-pip -y

# Verify installation
python3 --version
# Should show: Python 3.10.x or higher

pip3 --version
# Should show: pip 22.x or higher
```

### 2.5 Install Git

```bash
# Install Git
sudo apt install git -y

# Verify installation
git --version
# Should show: git version 2.x.x
```

### 2.6 Install Node.js (for dashboard - optional)

```bash
# Install Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Verify installation
node --version
# Should show: v18.x.x

npm --version
# Should show: 9.x.x or higher
```

---

## Step 3: Configure AWS Credentials (5 minutes)

### 3.1 Option A: Use IAM Role (Recommended - More Secure)

**Best practice for EC2 instances:**

1. Go to [IAM Console](https://console.aws.amazon.com/iam/)
2. Click **Roles** → **Create role**
3. Select **AWS service** → **EC2**
4. Attach policy: `AdministratorAccess` (for learning; use least privilege in production)
5. Name: `TerraformDeploymentRole`
6. Click **Create role**
7. Go back to [EC2 Console](https://console.aws.amazon.com/ec2/)
8. Select your deployment instance
9. **Actions** → **Security** → **Modify IAM role**
10. Select `TerraformDeploymentRole`
11. Click **Update IAM role**

**Verify:**
```bash
# Should show your account info without configuring credentials
aws sts get-caller-identity
```

### 3.2 Option B: Use Access Keys (Alternative)

If you can't use IAM roles:

```bash
# Configure AWS CLI
aws configure

# Enter when prompted:
AWS Access Key ID: [your access key]
AWS Secret Access Key: [your secret key]
Default region name: us-east-1
Default output format: json

# Verify
aws sts get-caller-identity
```

---

## Step 4: Enable Amazon Bedrock (5 minutes)

### 4.1 Enable Bedrock Access

```bash
# Check if Bedrock is accessible
aws bedrock list-foundation-models --region us-east-1 2>&1 | head -5

# If you see an error, enable via console:
```

**Via AWS Console:**
1. Go to [Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Make sure region is **us-east-1** (top right)
3. Click **Model access** (left sidebar)
4. Click **Enable specific models**
5. Find **Claude 3 Haiku** by Anthropic
6. Click **Enable**
7. Click **Submit**
8. Wait for "Access granted" status

**Verify:**
```bash
aws bedrock list-foundation-models --region us-east-1 | grep -i haiku
# Should show Claude 3 Haiku model info
```

---

## Step 5: Clone and Configure Project (5 minutes)

### 5.1 Clone Repository

```bash
# Clone the project
git clone https://github.com/Rishabh1623/aws-bedrock-fraud-detection.git

# Navigate into directory
cd aws-bedrock-fraud-detection

# Verify structure
ls -la
# Should see: infrastructure/, api/, model/, docs/, etc.
```

### 5.2 Configure Terraform Variables

```bash
# Go to infrastructure directory
cd infrastructure

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
# Or use vim: vim terraform.tfvars
```

**Update these values in `terraform.tfvars`:**

```hcl
aws_region      = "us-east-1"
project_name    = "fraud-detection-rft"
environment     = "dev"
owner_email     = "YOUR_EMAIL@example.com"  # ← Change this

# Get your current IP for SSH access
# Run: curl ifconfig.me
allowed_ssh_cidr = ["YOUR_IP/32"]  # ← Change this

# For testing, use smaller/cheaper resources
ec2_instance_type = "t3.small"     # Cheaper than t3.medium
enable_multi_az   = false          # Single AZ for testing
enable_waf        = false          # Not needed for testing
```

**Save and exit:**
- In nano: `Ctrl+X`, then `Y`, then `Enter`
- In vim: Press `Esc`, type `:wq`, press `Enter`

---

## Step 6: Deploy Infrastructure (15 minutes)

### 6.1 Initialize Terraform

```bash
# Make sure you're in infrastructure/ directory
pwd
# Should show: /home/ubuntu/aws-bedrock-fraud-detection/infrastructure

# Initialize Terraform
terraform init

# You should see: "Terraform has been successfully initialized!"
```

### 6.2 Preview Changes

```bash
# See what will be created
terraform plan

# Review the output
# Should show ~35-40 resources to be created
```

### 6.3 Deploy!

```bash
# Deploy everything
terraform apply

# Type 'yes' when prompted
```

**⏱️ This takes 10-15 minutes.** You'll see resources being created:

```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s
aws_subnet.public[0]: Creating...
aws_internet_gateway.main: Creating...
...
Apply complete! Resources: 35 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "fraud-detection-rft-alb-1234567890.us-east-1.elb.amazonaws.com"
api_endpoint = "http://fraud-detection-rft-alb-1234567890.us-east-1.elb.amazonaws.com/score"
...
```

**💾 SAVE THE OUTPUTS!** Especially the `alb_dns_name`.

---

## Step 7: Wait for System to Boot (5-10 minutes)

The infrastructure is created, but EC2 instances need time to boot and install the application.

### 7.1 Check Instance Status

```bash
# Check if instances are running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=fraud-detection-rft-api-server" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,LaunchTime]" \
  --output table
```

### 7.2 Monitor Target Health

```bash
# Check if ALB sees instances as healthy
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names fraud-detection-rft-api-tg \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)

# Wait until you see: "State": "healthy"
# This can take 5-10 minutes
```

**Pro tip:** Run this in a loop to monitor:
```bash
watch -n 30 'aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names fraud-detection-rft-api-tg --query "TargetGroups[0].TargetGroupArn" --output text) --query "TargetHealthDescriptions[].TargetHealth.State"'
```

Press `Ctrl+C` to stop watching.

---

## Step 8: Test Your API (5 minutes)

### 8.1 Get API Endpoint

```bash
# Get ALB DNS name
cd ~/aws-bedrock-fraud-detection/infrastructure
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "API Endpoint: http://$ALB_DNS"
```

### 8.2 Test Health Check

```bash
# Test health endpoint
curl http://$ALB_DNS/health

# Expected response:
# {"status":"healthy","timestamp":"2024-12-03T..."}
```

If you get an error, wait a few more minutes and try again.

### 8.3 Test Fraud Detection

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

# Expected: "risk_level":"LOW"
```

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

# Expected: "risk_level":"HIGH"
```

### 8.4 Run Automated Tests

```bash
cd ~/aws-bedrock-fraud-detection
bash scripts/test_api.sh http://$ALB_DNS
```

---

## Step 9: Monitor Your Infrastructure (Optional)

### 9.1 View Application Logs

```bash
# Stream live logs
aws logs tail /aws/ec2/fraud-detection-rft --follow

# View recent logs (last 10 minutes)
aws logs tail /aws/ec2/fraud-detection-rft --since 10m
```

### 9.2 Check DynamoDB Data

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

### 9.3 Check CloudWatch Metrics

```bash
# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=fraud-detection-rft-asg \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

---

## Step 10: Cleanup (5 minutes)

**IMPORTANT:** Destroy resources when done to avoid charges.

### 10.1 Destroy Infrastructure

```bash
cd ~/aws-bedrock-fraud-detection/infrastructure

# Destroy everything
terraform destroy

# Type 'yes' when prompted
# Takes 5-10 minutes
```

### 10.2 Verify Cleanup

```bash
# Check if resources are deleted
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=fraud-detection-rft" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]"

# Should show empty or "terminated"
```

### 10.3 Terminate Deployment Server (Optional)

If you're done with the deployment server:

1. Go to [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Select your `terraform-deployment-server` instance
3. **Instance State** → **Terminate instance**

---

## 🎉 Success!

You've successfully:
- ✅ Set up an Ubuntu EC2 deployment server
- ✅ Installed all required tools (Terraform, AWS CLI, Python)
- ✅ Deployed production-grade fraud detection infrastructure
- ✅ Tested the API with real transactions
- ✅ Monitored the system
- ✅ Cleaned up resources

---

## 🐛 Troubleshooting

### Issue: "Permission denied" when running Terraform

**Solution:**
```bash
# Make sure IAM role is attached or AWS credentials are configured
aws sts get-caller-identity
```

### Issue: Terraform init fails

**Solution:**
```bash
# Check internet connectivity
ping -c 3 google.com

# Check Terraform installation
terraform --version
```

### Issue: API returns 503

**Solution:**
```bash
# Wait longer - instances take 5-10 minutes to boot
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names fraud-detection-rft-api-tg \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)
```

### Issue: Can't connect to EC2 instance

**Solution:**
```bash
# Check security group allows SSH from your IP
# Get your current IP: curl ifconfig.me
# Update security group in EC2 console if needed
```

### Issue: Bedrock access denied

**Solution:**
```bash
# Enable Bedrock model access in console
# Go to: https://console.aws.amazon.com/bedrock/
# Enable Claude 3 Haiku model
```

---

## 💰 Cost Estimate

**Deployment Server (t2.micro):** $0.01/hour = ~$0.24/day  
**Fraud Detection Infrastructure:** ~$2-3/day  
**Total:** ~$2.50-3.50/day while running

**To minimize costs:**
- Destroy infrastructure when not in use
- Use t3.small instead of t3.medium
- Set enable_multi_az = false

---

## 📚 Next Steps

1. **Generate Training Data**
   ```bash
   cd ~/aws-bedrock-fraud-detection/data
   python3 generate_sample_data.py
   ```

2. **Train Custom Model** (optional, costs $50-100)
   ```bash
   cd ~/aws-bedrock-fraud-detection/model
   pip3 install -r requirements.txt
   python3 train_rft.py --dataset ../data/training/fraud_samples.jsonl --bucket YOUR_S3_BUCKET
   ```

3. **Deploy Dashboard** (optional)
   ```bash
   cd ~/aws-bedrock-fraud-detection/dashboard
   npm install
   npm run dev
   ```

4. **Add to Portfolio**
   - Take screenshots of working system
   - Document your deployment process
   - Add to resume and LinkedIn

---

## 🆘 Need Help?

- 📖 [Main README](README.md)
- 🏗️ [Architecture Guide](docs/ARCHITECTURE.md)
- 💬 [GitHub Issues](https://github.com/Rishabh1623/aws-bedrock-fraud-detection/issues)

**Happy deploying!** 🚀
