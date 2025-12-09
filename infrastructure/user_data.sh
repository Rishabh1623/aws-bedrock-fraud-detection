#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting fraud detection API setup..."

# Update system (works for both Amazon Linux and Ubuntu)
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y python3 python3-pip git curl wget unzip
    
    # Install Docker
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    
    PYTHON_CMD="python3"
    USER="ubuntu"
else
    # Amazon Linux
    yum update -y
    yum install -y python3 python3-pip git curl wget unzip
    
    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    PYTHON_CMD="python3"
    USER="ec2-user"
fi

# Install pip packages
$PYTHON_CMD -m pip install --upgrade pip
$PYTHON_CMD -m pip install fastapi uvicorn boto3 pydantic

# Install AWS CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb || yum install -y amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/fraud-detection/api
mkdir -p /var/log/fraud-detection
chown -R $USER:$USER /opt/fraud-detection
chown -R $USER:$USER /var/log/fraud-detection

# Clone application code
cd /opt/fraud-detection
git clone https://github.com/Rishabh1623/aws-bedrock-fraud-detection.git temp
cp -r temp/api/* api/
rm -rf temp

# Create environment file
cat > /opt/fraud-detection/.env <<EOF
AWS_REGION=${aws_region}
DYNAMODB_TABLE=${dynamodb_table}
S3_BUCKET=${s3_bucket}
MODEL_ID=${model_id}
SNS_TOPIC_ARN=${sns_topic_arn}
PROJECT_NAME=${project_name}
EOF

# Create systemd service
cat > /etc/systemd/system/fraud-detection.service <<SYSTEMD
[Unit]
Description=Fraud Detection API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/fraud-detection/api
EnvironmentFile=/opt/fraud-detection/.env
ExecStart=$PYTHON_CMD -m uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10
StandardOutput=append:/var/log/fraud-detection/api.log
StandardError=append:/var/log/fraud-detection/api-error.log

[Install]
WantedBy=multi-user.target
SYSTEMD

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'CW'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/fraud-detection/*.log",
            "log_group_name": "/aws/ec2/${project_name}",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}",
    "metrics_collected": {
      "cpu": {
        "measurement": [{"name": "cpu_usage_idle"}],
        "totalcpu": false
      },
      "mem": {
        "measurement": [{"name": "mem_used_percent"}]
      }
    }
  }
}
CW

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json || echo "CloudWatch agent failed to start"

# Enable and start service
systemctl daemon-reload
systemctl enable fraud-detection
systemctl start fraud-detection

# Wait for service to start
sleep 10

# Check service status
systemctl status fraud-detection --no-pager || echo "Service not running yet"

echo "Fraud Detection API setup complete!"
echo "Check logs: journalctl -u fraud-detection -f"
