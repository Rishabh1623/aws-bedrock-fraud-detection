# Production Readiness Checklist

## ✅ Pre-Deployment Verification

This checklist ensures everything is ready for deployment. Review before running `terraform apply`.

---

## 🔍 Critical Files Verified

### ✅ 1. DEPLOY_FROM_EC2.md
- [x] All commands are Ubuntu-compatible
- [x] Step-by-step instructions are accurate
- [x] Amazon Nova Lite model references are correct
- [x] IAM role setup is documented
- [x] Troubleshooting section is comprehensive
- [x] Cost estimates are accurate

### ✅ 2. Infrastructure Code (Terraform)
- [x] `variables.tf` - Default model is `amazon.nova-lite-v1:0`
- [x] `main.tf` - Provider configuration is correct
- [x] `vpc.tf` - VPC, subnets, NAT gateway configured
- [x] `alb.tf` - Load balancer with health checks
- [x] `ec2.tf` - Auto Scaling Group with proper IAM roles
- [x] `monitoring.tf` - CloudWatch dashboards and alarms
- [x] `user_data.sh` - **FIXED** - Now works with Amazon Linux 2023
- [x] `outputs.tf` - All necessary outputs defined

### ✅ 3. Application Code
- [x] `api/app.py` - Uses `amazon.nova-lite-v1:0`
- [x] `api/requirements.txt` - All dependencies listed
- [x] Health check endpoint (`/health`) implemented
- [x] Error handling and logging configured
- [x] CloudWatch metrics integration

### ✅ 4. Training Scripts
- [x] `model/train_rft.py` - Default model is Nova Lite
- [x] `model/requirements.txt` - Dependencies listed
- [x] `data/generate_sample_data.py` - Generates test data

### ✅ 5. Documentation
- [x] `README.md` - Updated with Nova Lite references
- [x] `PROJECT_PURPOSE.md` - Career goals and ROI explained
- [x] `docs/BEDROCK_RFT_MODELS.md` - Model comparison guide
- [x] `docs/INTERVIEW_GUIDE.md` - Interview preparation
- [x] `docs/AWS_SA_PORTFOLIO.md` - Portfolio showcase guide

---

## 🚨 Critical Issues Fixed

### Issue 1: user_data.sh Used Wrong Package Manager ✅ FIXED
**Problem:** Script used `yum` (Amazon Linux) but we're using Amazon Linux 2023 AMI  
**Solution:** Updated script to work with Amazon Linux 2023  
**Status:** ✅ Fixed and tested

### Issue 2: Model References ✅ FIXED
**Problem:** Some files still referenced Claude 3 Haiku  
**Solution:** Updated all files to use `amazon.nova-lite-v1:0`  
**Status:** ✅ All files updated

---

## 📋 Deployment Checklist

### Before You Start

- [ ] Read `PROJECT_PURPOSE.md` - Understand WHY you're building this
- [ ] Read `DEPLOY_FROM_EC2.md` completely - Don't skip steps
- [ ] Have AWS account with admin access
- [ ] Have credit card on file (even for free tier)
- [ ] Know your public IP address (`curl ifconfig.me`)

### AWS Account Setup

- [ ] AWS account created and verified
- [ ] IAM user created with AdministratorAccess
- [ ] Access keys generated (or IAM role ready)
- [ ] Bedrock access enabled in us-east-1
- [ ] Amazon Nova Lite model access granted

### EC2 Deployment Server

- [ ] Ubuntu 22.04 LTS EC2 instance launched
- [ ] t2.micro or t3.micro (free tier)
- [ ] IAM role attached (TerraformDeploymentRole)
- [ ] Security group allows SSH from your IP
- [ ] Can connect via SSH or EC2 Instance Connect

### Tools Installed

- [ ] AWS CLI v2 installed (`aws --version`)
- [ ] Terraform >= 1.0 installed (`terraform --version`)
- [ ] Python 3.10+ installed (`python3 --version`)
- [ ] Git installed (`git --version`)
- [ ] Can run `aws sts get-caller-identity` successfully

### Project Configuration

- [ ] Repository cloned to EC2 instance
- [ ] `terraform.tfvars` created from example
- [ ] `owner_email` updated with your email
- [ ] `allowed_ssh_cidr` updated with your IP
- [ ] `bedrock_model_id` is `amazon.nova-lite-v1:0`
- [ ] `ec2_instance_type` is `t3.small` (for testing)
- [ ] `enable_multi_az` is `false` (for testing)

---

## 🎯 Deployment Steps

### Step 1: Initialize Terraform
```bash
cd ~/aws-bedrock-fraud-detection/infrastructure
terraform init
```
**Expected:** "Terraform has been successfully initialized!"

### Step 2: Plan Deployment
```bash
terraform plan
```
**Expected:** ~35-40 resources to be created

### Step 3: Deploy Infrastructure
```bash
terraform apply
```
**Expected:** Takes 10-15 minutes, outputs ALB DNS name

### Step 4: Wait for Instances
**Wait:** 5-10 minutes for EC2 instances to boot and install app

### Step 5: Test API
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/health
```
**Expected:** `{"status":"healthy",...}`

### Step 6: Test Fraud Detection
```bash
curl -X POST http://$ALB_DNS/score \
  -H "Content-Type: application/json" \
  -d '{"transaction":{"transaction_id":"TEST001","amount":45.99,"merchant":"Amazon","location":"New York","card_present":true,"recent_transaction_count":2}}'
```
**Expected:** `{"risk_level":"LOW",...}`

---

## ✅ Post-Deployment Verification

### Infrastructure Checks

- [ ] VPC created with public and private subnets
- [ ] ALB is active and healthy
- [ ] Target group shows healthy targets
- [ ] Auto Scaling Group has running instances
- [ ] DynamoDB table exists
- [ ] S3 buckets created
- [ ] CloudWatch log group exists
- [ ] SNS topic created

### Application Checks

- [ ] Health endpoint returns 200 OK
- [ ] API responds to fraud detection requests
- [ ] Transactions are logged in DynamoDB
- [ ] CloudWatch logs show application output
- [ ] No errors in application logs

### AWS Console Verification

- [ ] EC2 Dashboard shows running instances
- [ ] Load Balancers shows healthy targets
- [ ] VPC shows custom VPC with subnets
- [ ] DynamoDB shows transactions table
- [ ] CloudWatch shows metrics and logs

---

## 🐛 Common Issues & Solutions

### Issue: Terraform init fails
**Solution:** Check internet connectivity, verify Terraform installation

### Issue: Terraform apply fails with "InvalidParameterException"
**Solution:** Enable Bedrock model access in AWS Console

### Issue: API returns 503 Service Unavailable
**Solution:** Wait 10 minutes for instances to fully boot

### Issue: Health check fails
**Solution:** Check target group health in ALB console

### Issue: Can't SSH to deployment server
**Solution:** Verify security group allows SSH from your IP

### Issue: Bedrock access denied
**Solution:** Enable Amazon Nova Lite in Bedrock console

---

## 💰 Cost Monitoring

### Daily Cost Estimate
- Deployment Server (t2.micro): $0.24/day
- Fraud Detection Infrastructure: $2-3/day
- **Total: ~$2.50-3.50/day**

### Cost Optimization
- [ ] Destroy infrastructure when not in use
- [ ] Use t3.small instead of t3.medium
- [ ] Set enable_multi_az = false for testing
- [ ] Monitor costs in AWS Cost Explorer

### Cleanup Checklist
- [ ] Run `terraform destroy` when done
- [ ] Verify all resources deleted in AWS Console
- [ ] Terminate deployment server if no longer needed
- [ ] Check AWS billing dashboard

---

## 📊 Success Metrics

### Technical Success
- [ ] Infrastructure deploys without errors
- [ ] API responds in <100ms
- [ ] All health checks pass
- [ ] Can process 100+ test transactions

### Portfolio Success
- [ ] Screenshots taken of working system
- [ ] Architecture diagram created
- [ ] Demo video recorded (optional)
- [ ] Blog post drafted (optional)

### Career Success
- [ ] Resume updated with project
- [ ] LinkedIn profile updated
- [ ] Ready to discuss in interviews
- [ ] Can explain architecture confidently

---

## 🎉 You're Ready!

If all items above are checked, you're ready to deploy!

**Next Steps:**
1. Follow `DEPLOY_FROM_EC2.md` step-by-step
2. Don't skip any steps
3. Take screenshots as you go
4. Document any issues you encounter
5. Celebrate when it works! 🎊

**Remember:** This is a strategic career investment. Every hour you spend on this project is an investment in your future.

**Good luck!** 🚀
