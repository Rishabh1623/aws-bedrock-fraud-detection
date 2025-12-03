# Pre-Deployment Checklist

Complete this checklist before deploying to avoid common issues.

## ✅ AWS Account Setup

- [ ] AWS Account created and verified
- [ ] Credit card added (required even for free tier)
- [ ] Account not in suspended state
- [ ] Root user MFA enabled (security best practice)

## ✅ IAM User Setup

- [ ] IAM user created with admin access
- [ ] Access Key ID and Secret Access Key generated
- [ ] Keys saved securely (never commit to Git)
- [ ] MFA enabled on IAM user (recommended)

## ✅ AWS CLI Configuration

```bash
# Test these commands:
aws --version                    # Should show version 2.x
aws sts get-caller-identity      # Should show your account ID
aws ec2 describe-regions         # Should list AWS regions
```

- [ ] AWS CLI installed (version 2.x)
- [ ] Credentials configured (`aws configure`)
- [ ] Default region set to `us-east-1` or `us-west-2`
- [ ] Can run AWS commands successfully

## ✅ Bedrock Access

```bash
# Test Bedrock access:
aws bedrock list-foundation-models --region us-east-1
```

- [ ] Bedrock console accessed
- [ ] Model access requested for Claude 3 Haiku
- [ ] Access approved (usually instant)
- [ ] Can list foundation models via CLI

## ✅ Local Tools Installed

```bash
# Verify installations:
terraform --version              # Should show v1.0+
python --version                 # Should show 3.11+
node --version                   # Should show 18+
git --version                    # Should show 2.x+
```

- [ ] Terraform >= 1.0 installed
- [ ] Python >= 3.11 installed
- [ ] Node.js >= 18 installed
- [ ] Git installed
- [ ] Text editor ready (VS Code, Sublime, etc.)

## ✅ Network & Security

```bash
# Get your public IP:
curl ifconfig.me
```

- [ ] Know your public IP address
- [ ] Firewall allows outbound HTTPS (port 443)
- [ ] No corporate VPN blocking AWS API calls
- [ ] Can access AWS Console in browser

## ✅ Cost Awareness

- [ ] Understand estimated costs (~$2-3/day for testing)
- [ ] Set up billing alerts in AWS Console
- [ ] Know how to destroy resources (`terraform destroy`)
- [ ] Plan to destroy after testing/demo

### Set Up Billing Alert

1. Go to [AWS Billing Console](https://console.aws.amazon.com/billing/)
2. Click "Billing preferences"
3. Enable "Receive Billing Alerts"
4. Go to [CloudWatch Alarms](https://console.aws.amazon.com/cloudwatch/)
5. Create alarm for "EstimatedCharges" > $10

## ✅ Repository Setup

```bash
# Clone and verify:
git clone https://github.com/Rishabh1623/aws-bedrock-fraud-detection.git
cd aws-bedrock-fraud-detection
ls -la  # Should see infrastructure/, api/, docs/, etc.
```

- [ ] Repository cloned successfully
- [ ] Can see all directories (infrastructure, api, model, etc.)
- [ ] No permission errors

## ✅ Configuration Files

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
```

- [ ] `terraform.tfvars` created from example
- [ ] `owner_email` updated with your email
- [ ] `allowed_ssh_cidr` updated with your IP
- [ ] `aws_region` set to supported region (us-east-1 or us-west-2)

## ✅ Pre-Flight Checks

```bash
# Run these before terraform apply:
cd infrastructure
terraform fmt -check             # Check formatting
terraform validate               # Validate syntax
```

- [ ] Terraform files formatted correctly
- [ ] Terraform configuration valid
- [ ] No syntax errors

## ✅ Estimated Timeline

- Setup prerequisites: 15-30 minutes
- Terraform deployment: 10-15 minutes
- EC2 instance boot: 5-10 minutes
- Testing and validation: 10-15 minutes
- **Total: 40-70 minutes**

## ✅ Support Resources Ready

- [ ] AWS documentation bookmarked
- [ ] Terraform docs bookmarked
- [ ] GitHub Issues page bookmarked
- [ ] Know where to get help

## 🚀 Ready to Deploy?

If all items are checked, you're ready to proceed with deployment!

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## 📞 Need Help?

If any checklist item fails:

1. **AWS CLI issues**: [AWS CLI Troubleshooting](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html)
2. **Bedrock access**: [Bedrock Model Access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html)
3. **Terraform issues**: [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
4. **General help**: Open an [Issue](https://github.com/Rishabh1623/aws-bedrock-fraud-detection/issues)

Good luck! 🎉
