#!/bin/bash
# Script to empty and delete old S3 buckets

BUCKET_NAME="fraud-detection-rft-alb-logs-543927035352"

echo "Emptying S3 bucket: $BUCKET_NAME"
aws s3 rm s3://$BUCKET_NAME --recursive

echo "Deleting S3 bucket: $BUCKET_NAME"
aws s3 rb s3://$BUCKET_NAME

echo "Cleanup complete!"
