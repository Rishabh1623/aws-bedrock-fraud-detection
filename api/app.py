"""
FastAPI application for fraud detection
Production-ready with health checks, metrics, and error handling
"""
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import boto3
import os
import time
import json
from datetime import datetime
from typing import Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.getenv('AWS_REGION', 'us-east-1'))
events = boto3.client('events', region_name=os.getenv('AWS_REGION', 'us-east-1'))
cloudwatch = boto3.client('cloudwatch', region_name=os.getenv('AWS_REGION', 'us-east-1'))

# Configuration
TABLE_NAME = os.getenv('DYNAMODB_TABLE', 'fraud-detection-rft-transactions')
MODEL_ID = os.getenv('MODEL_ID', 'anthropic.claude-3-haiku-20240307-v1:0')
PROJECT_NAME = os.getenv('PROJECT_NAME', 'fraud-detection-rft')

app = FastAPI(
    title="Fraud Detection API",
    description="Real-time fraud detection using Amazon Bedrock RFT",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response Models
class Transaction(BaseModel):
    transaction_id: str = Field(..., description="Unique transaction ID")
    amount: float = Field(..., gt=0, description="Transaction amount")
    merchant: str = Field(..., description="Merchant name")
    location: str = Field(..., description="Transaction location")
    card_present: bool = Field(default=False, description="Card present flag")
    recent_transaction_count: int = Field(default=0, ge=0, description="Recent transaction count")
    timestamp: Optional[str] = Field(default=None, description="Transaction timestamp")

class ScoreRequest(BaseModel):
    transaction: Transaction

class ScoreResponse(BaseModel):
    transaction_id: str
    risk_score: float
    risk_level: str
    explanation: str
    latency_ms: float
    timestamp: str

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check for ALB target group"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# Readiness check
@app.get("/ready")
async def readiness_check():
    """Check if service is ready to handle requests"""
    try:
        # Test DynamoDB connection
        table = dynamodb.Table(TABLE_NAME)
        table.table_status
        return {"status": "ready", "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")

# Main scoring endpoint
@app.post("/score", response_model=ScoreResponse)
async def score_transaction(request: ScoreRequest):
    """Score a transaction for fraud risk"""
    start_time = time.time()
    
    try:
        transaction = request.transaction
        
        # Score transaction
        risk_score, explanation = await _score_with_bedrock(transaction)
        
        # Store in DynamoDB
        await _store_transaction(transaction, risk_score, explanation)
        
        # Trigger alert if high risk
        if risk_score > 0.8:
            await _trigger_fraud_alert(transaction, risk_score)
        
        # Send metrics to CloudWatch
        await _send_metrics(risk_score, time.time() - start_time)
        
        latency = (time.time() - start_time) * 1000
        
        return ScoreResponse(
            transaction_id=transaction.transaction_id,
            risk_score=round(risk_score, 4),
            risk_level=_get_risk_level(risk_score),
            explanation=explanation,
            latency_ms=round(latency, 2),
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Error scoring transaction: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Metrics endpoint
@app.get("/metrics")
async def get_metrics():
    """Get API metrics"""
    try:
        table = dynamodb.Table(TABLE_NAME)
        
        # Get recent transactions
        response = table.scan(Limit=1000)
        items = response.get('Items', [])
        
        total = len(items)
        fraud_count = sum(1 for item in items if float(item.get('risk_score', 0)) > 0.8)
        
        return {
            "total_transactions": total,
            "fraud_detected": fraud_count,
            "fraud_rate": round(fraud_count / total * 100, 2) if total > 0 else 0,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error fetching metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Helper functions
async def _score_with_bedrock(transaction: Transaction) -> tuple[float, str]:
    """Score transaction using Bedrock model"""
    prompt = f"""Analyze this transaction for fraud indicators:

Transaction Details:
- Amount: ${transaction.amount}
- Merchant: {transaction.merchant}
- Location: {transaction.location}
- Card Present: {transaction.card_present}
- Time: {transaction.timestamp or datetime.now().isoformat()}
- Recent transactions (24h): {transaction.recent_transaction_count}

Provide a fraud risk score (0.0-1.0) and brief explanation."""

    try:
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 200,
                "messages": [{
                    "role": "user",
                    "content": prompt
                }]
            })
        )
        
        result = json.loads(response['body'].read())
        content = result['content'][0]['text']
        
        # Extract risk score
        risk_score = _extract_risk_score(content)
        
        return risk_score, content
        
    except Exception as e:
        logger.error(f"Bedrock error: {e}")
        return 0.5, "Error during scoring"

def _extract_risk_score(text: str) -> float:
    """Extract numeric risk score from model response"""
    import re
    match = re.search(r'(\d+\.?\d*)', text)
    if match:
        score = float(match.group(1))
        return min(max(score, 0.0), 1.0)
    return 0.5

async def _store_transaction(transaction: Transaction, risk_score: float, explanation: str):
    """Store transaction in DynamoDB"""
    table = dynamodb.Table(TABLE_NAME)
    
    table.put_item(Item={
        'transaction_id': transaction.transaction_id,
        'timestamp': int(time.time()),
        'amount': str(transaction.amount),
        'merchant': transaction.merchant,
        'location': transaction.location,
        'risk_score': str(risk_score),
        'explanation': explanation,
        'flagged': risk_score > 0.8
    })

async def _trigger_fraud_alert(transaction: Transaction, risk_score: float):
    """Send high-risk transaction to EventBridge"""
    events.put_events(
        Entries=[{
            'Source': 'custom.frauddetection',
            'DetailType': 'Transaction Scored',
            'Detail': json.dumps({
                'transaction_id': transaction.transaction_id,
                'risk_score': risk_score,
                'amount': transaction.amount,
                'merchant': transaction.merchant
            })
        }]
    )

async def _send_metrics(risk_score: float, latency: float):
    """Send custom metrics to CloudWatch"""
    cloudwatch.put_metric_data(
        Namespace=PROJECT_NAME,
        MetricData=[
            {
                'MetricName': 'TransactionLatency',
                'Value': latency * 1000,
                'Unit': 'Milliseconds'
            },
            {
                'MetricName': 'RiskScore',
                'Value': risk_score,
                'Unit': 'None'
            }
        ]
    )

def _get_risk_level(score: float) -> str:
    """Convert score to risk level"""
    if score >= 0.8:
        return "HIGH"
    elif score >= 0.5:
        return "MEDIUM"
    return "LOW"

# Exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
