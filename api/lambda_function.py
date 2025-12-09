import json
import boto3
import os
from datetime import datetime
import time

bedrock_runtime = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')

TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'fraud-detection-rft-transactions')
MODEL_ID = os.environ.get('MODEL_ID', 'amazon.nova-lite-v1:0')

def lambda_handler(event, context):
    """Real-time fraud detection API"""
    start_time = time.time()
    
    try:
        # Handle health check
        if event.get('rawPath') == '/health' or event.get('path') == '/health':
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'status': 'healthy'})
            }
        
        # Parse transaction
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event
        # Support both nested and direct transaction format
        transaction = body.get('transaction', body)
        
        # Score transaction
        risk_score, explanation = score_transaction(transaction)
        
        # Store in DynamoDB
        store_transaction(transaction, risk_score, explanation)
        
        # Trigger alert if high risk
        if risk_score > 0.8:
            trigger_fraud_alert(transaction, risk_score)
        
        latency = (time.time() - start_time) * 1000
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'transaction_id': transaction.get('transaction_id'),
                'risk_score': risk_score,
                'risk_level': get_risk_level(risk_score),
                'explanation': explanation,
                'latency_ms': round(latency, 2)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def score_transaction(transaction):
    """Score transaction using Bedrock RFT model"""
    prompt = f"""Analyze this financial transaction for risk indicators:

Transaction Details:
- Amount: ${transaction.get('amount', 0)}
- Merchant: {transaction.get('merchant', 'Unknown')}
- Location: {transaction.get('location', 'Unknown')}
- Card Present: {transaction.get('card_present', False)}
- Time: {transaction.get('timestamp', datetime.now().isoformat())}
- Recent transactions (24h): {transaction.get('recent_transaction_count', 0)}

Provide a risk score from 0.0 (safe) to 1.0 (suspicious) and brief explanation.
Format: Score: X.XX - Explanation"""

    try:
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "messages": [{
                    "role": "user",
                    "content": [{"text": prompt}]
                }],
                "inferenceConfig": {
                    "max_new_tokens": 200,
                    "temperature": 0.7
                }
            })
        )
        
        result = json.loads(response['body'].read())
        content = result['output']['message']['content'][0]['text']
        
        # Parse risk score from response
        risk_score = extract_risk_score(content)
        
        return risk_score, content
        
    except Exception as e:
        print(f"Error scoring transaction: {e}")
        return 0.5, "Error during scoring"

def extract_risk_score(text):
    """Extract numeric risk score from model response"""
    import re
    match = re.search(r'(\d+\.?\d*)', text)
    if match:
        score = float(match.group(1))
        return min(max(score, 0.0), 1.0)
    return 0.5

def store_transaction(transaction, risk_score, explanation):
    """Store transaction in DynamoDB"""
    table = dynamodb.Table(TABLE_NAME)
    
    table.put_item(Item={
        'transaction_id': transaction.get('transaction_id', str(time.time())),
        'timestamp': int(time.time()),
        'amount': str(transaction.get('amount', 0)),
        'merchant': transaction.get('merchant', 'Unknown'),
        'risk_score': str(risk_score),
        'explanation': explanation,
        'flagged': risk_score > 0.8
    })

def trigger_fraud_alert(transaction, risk_score):
    """Send high-risk transaction to EventBridge"""
    events.put_events(
        Entries=[{
            'Source': 'custom.frauddetection',
            'DetailType': 'Transaction Scored',
            'Detail': json.dumps({
                'transaction_id': transaction.get('transaction_id'),
                'risk_score': risk_score,
                'amount': transaction.get('amount'),
                'merchant': transaction.get('merchant')
            })
        }]
    )

def get_risk_level(score):
    """Convert score to risk level"""
    if score >= 0.8:
        return "HIGH"
    elif score >= 0.5:
        return "MEDIUM"
    return "LOW"
