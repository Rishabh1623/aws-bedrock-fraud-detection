import boto3
import json
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import numpy as np

class ModelEvaluator:
    def __init__(self, model_id, region='us-east-1'):
        self.bedrock = boto3.client('bedrock-runtime', region_name=region)
        self.model_id = model_id
    
    def evaluate(self, test_data_path):
        """Evaluate model on test dataset"""
        # Load test data
        with open(test_data_path, 'r') as f:
            test_data = [json.loads(line) for line in f]
        
        predictions = []
        actuals = []
        scores = []
        latencies = []
        
        print(f"Evaluating {len(test_data)} transactions...")
        
        for i, transaction in enumerate(test_data):
            if i % 50 == 0:
                print(f"Progress: {i}/{len(test_data)}")
            
            # Get prediction
            score, latency = self.score_transaction(transaction)
            
            predictions.append(1 if score > 0.5 else 0)
            actuals.append(1 if transaction['is_fraud'] else 0)
            scores.append(score)
            latencies.append(latency)
        
        # Calculate metrics
        print("\n" + "="*50)
        print("EVALUATION RESULTS")
        print("="*50)
        
        print("\nClassification Report:")
        print(classification_report(actuals, predictions, 
                                   target_names=['Normal', 'Fraud']))
        
        print("\nConfusion Matrix:")
        cm = confusion_matrix(actuals, predictions)
        print(f"True Negatives: {cm[0][0]}")
        print(f"False Positives: {cm[0][1]}")
        print(f"False Negatives: {cm[1][0]}")
        print(f"True Positives: {cm[1][1]}")
        
        print(f"\nROC AUC Score: {roc_auc_score(actuals, scores):.4f}")
        print(f"Average Latency: {np.mean(latencies):.2f}ms")
        print(f"P95 Latency: {np.percentile(latencies, 95):.2f}ms")
        
        # Calculate cost savings
        base_cost = len(test_data) * 0.002  # Large model cost
        rft_cost = len(test_data) * 0.0001  # RFT model cost
        savings = ((base_cost - rft_cost) / base_cost) * 100
        
        print(f"\nCost Analysis:")
        print(f"Base Model Cost: ${base_cost:.2f}")
        print(f"RFT Model Cost: ${rft_cost:.2f}")
        print(f"Savings: {savings:.1f}%")
        
        return {
            'predictions': predictions,
            'actuals': actuals,
            'scores': scores,
            'latencies': latencies
        }
    
    def score_transaction(self, transaction):
        """Score a single transaction"""
        import time
        
        prompt = self._create_prompt(transaction)
        
        start = time.time()
        
        try:
            response = self.bedrock.invoke_model(
                modelId=self.model_id,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 100,
                    "messages": [{
                        "role": "user",
                        "content": prompt
                    }]
                })
            )
            
            latency = (time.time() - start) * 1000
            
            result = json.loads(response['body'].read())
            content = result['content'][0]['text']
            
            # Extract score
            score = self._extract_score(content)
            
            return score, latency
            
        except Exception as e:
            print(f"Error scoring transaction: {e}")
            return 0.5, 0
    
    def _create_prompt(self, transaction):
        return f"""Analyze this transaction for fraud:
Amount: ${transaction['amount']}
Merchant: {transaction['merchant']}
Location: {transaction['location']}
Card Present: {transaction.get('card_present', False)}
Recent transactions: {transaction.get('recent_transaction_count', 0)}

Provide fraud risk score (0.0-1.0)."""
    
    def _extract_score(self, text):
        import re
        match = re.search(r'(\d+\.?\d*)', text)
        if match:
            score = float(match.group(1))
            return min(max(score, 0.0), 1.0)
        return 0.5

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--model-id', required=True, help='Bedrock model ID')
    parser.add_argument('--test-data', required=True, help='Path to test data')
    
    args = parser.parse_args()
    
    evaluator = ModelEvaluator(args.model_id)
    results = evaluator.evaluate(args.test_data)
