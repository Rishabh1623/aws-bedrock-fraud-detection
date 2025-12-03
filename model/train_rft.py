import boto3
import json
import argparse
from datetime import datetime

class BedrockRFTTrainer:
    def __init__(self, region='us-east-1'):
        self.bedrock = boto3.client('bedrock', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        
    def prepare_training_data(self, dataset_path, s3_bucket):
        """Upload training data to S3 in Bedrock RFT format"""
        with open(dataset_path, 'r') as f:
            data = [json.loads(line) for line in f]
        
        # Convert to Bedrock RFT format
        training_data = []
        for item in data:
            training_data.append({
                "prompt": self._create_prompt(item),
                "completion": json.dumps({"is_fraud": item["is_fraud"], "confidence": item.get("confidence", 0.9)}),
                "reward": 1.0 if item.get("correct_prediction", True) else -1.0
            })
        
        # Upload to S3
        s3_key = f"training-data/{datetime.now().strftime('%Y%m%d-%H%M%S')}.jsonl"
        training_file = '\n'.join([json.dumps(item) for item in training_data])
        
        self.s3.put_object(
            Bucket=s3_bucket,
            Key=s3_key,
            Body=training_file.encode('utf-8')
        )
        
        return f"s3://{s3_bucket}/{s3_key}"
    
    def _create_prompt(self, transaction):
        """Create prompt for fraud detection"""
        return f"""Analyze this transaction for fraud:
Amount: ${transaction['amount']}
Merchant: {transaction['merchant']}
Location: {transaction['location']}
Time: {transaction['timestamp']}
Card Present: {transaction.get('card_present', False)}
Previous 24h transactions: {transaction.get('recent_transaction_count', 0)}

Is this transaction fraudulent? Provide confidence score."""
    
    def start_rft_job(self, base_model_id, training_data_uri, output_bucket, job_name):
        """Start Bedrock RFT training job"""
        try:
            response = self.bedrock.create_model_customization_job(
                jobName=job_name,
                customModelName=f"{job_name}-model",
                roleArn=self._get_bedrock_role_arn(),
                baseModelIdentifier=base_model_id,
                trainingDataConfig={
                    "s3Uri": training_data_uri
                },
                outputDataConfig={
                    "s3Uri": f"s3://{output_bucket}/models/"
                },
                hyperParameters={
                    "epochCount": "3",
                    "batchSize": "8",
                    "learningRate": "0.00001"
                },
                customizationType="REINFORCEMENT_LEARNING"
            )
            
            print(f"RFT job started: {response['jobArn']}")
            return response['jobArn']
            
        except Exception as e:
            print(f"Error starting RFT job: {e}")
            raise
    
    def _get_bedrock_role_arn(self):
        """Get or create IAM role for Bedrock"""
        iam = boto3.client('iam')
        role_name = 'BedrockRFTRole'
        
        try:
            response = iam.get_role(RoleName=role_name)
            return response['Role']['Arn']
        except iam.exceptions.NoSuchEntityException:
            print(f"Please create IAM role '{role_name}' with Bedrock permissions")
            raise

def main():
    parser = argparse.ArgumentParser(description='Train fraud detection model with Bedrock RFT')
    parser.add_argument('--dataset', required=True, help='Path to training dataset (JSONL)')
    parser.add_argument('--bucket', required=True, help='S3 bucket for artifacts')
    parser.add_argument('--model', default='anthropic.claude-3-haiku-20240307-v1:0', help='Base model ID')
    parser.add_argument('--job-name', default=f'fraud-rft-{datetime.now().strftime("%Y%m%d-%H%M%S")}', help='Job name')
    
    args = parser.parse_args()
    
    trainer = BedrockRFTTrainer()
    
    print("Preparing training data...")
    training_uri = trainer.prepare_training_data(args.dataset, args.bucket)
    
    print("Starting RFT training job...")
    job_arn = trainer.start_rft_job(args.model, training_uri, args.bucket, args.job_name)
    
    print(f"\nTraining started successfully!")
    print(f"Job ARN: {job_arn}")
    print(f"Monitor progress in AWS Console: Bedrock > Custom models")

if __name__ == "__main__":
    main()
