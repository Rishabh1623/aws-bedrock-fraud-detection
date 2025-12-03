#!/bin/bash
set -e

# Update system
yum update -y

# Install dependencies
yum install -y python3.11 python3.11-pip git docker amazon-cloudwatch-agent

# Start Docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/fraud-detection
cd /opt/fraud-detection

# Clone application code (replace with your repo)
# git clone https://github.com/your-username/fraud-detection-rft.git .

# Create environment file
cat > .env <<EOF
AWS_REGION=${aws_region}
DYNAMODB_TABLE=${dynamodb_table}
S3_BUCKET=${s3_bucket}
MODEL_ID=${model_id}
SNS_TOPIC_ARN=${sns_topic_arn}
PROJECT_NAME=${project_name}
EOF

# Create systemd service
cat > /etc/systemd/system/fraud-detection.service <<'SYSTEMD'
[Unit]
Description=Fraud Detection API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/fraud-detection/api
EnvironmentFile=/opt/fraud-detection/.env
ExecStart=/usr/bin/python3.11 -m uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'CW'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/fraud-detection/*.log",
            "log_group_name": "/aws/ec2/${project_name}",
            "log_stream_name": "{instance_id}"
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
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Enable and start service
systemctl daemon-reload
systemctl enable fraud-detection
systemctl start fraud-detection

echo "Fraud Detection API setup complete"
