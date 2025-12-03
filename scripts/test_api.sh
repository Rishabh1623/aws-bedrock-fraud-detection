#!/bin/bash

# Test fraud detection API
# Usage: ./test_api.sh http://your-alb-dns.amazonaws.com

API_ENDPOINT="${1}"

if [ -z "$API_ENDPOINT" ]; then
  echo "Usage: $0 <API_ENDPOINT>"
  echo "Example: $0 http://fraud-detection-alb-123.us-east-1.elb.amazonaws.com"
  exit 1
fi

# Remove trailing slash
API_ENDPOINT="${API_ENDPOINT%/}"

echo "=========================================="
echo "  Testing Fraud Detection API"
echo "=========================================="
echo "Endpoint: $API_ENDPOINT"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test 0: Health Check
echo "Test 0: Health Check"
if curl -s -f "${API_ENDPOINT}/health" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Health check passed${NC}"
else
  echo -e "${RED}✗ Health check failed - API may not be ready yet${NC}"
  echo "Wait 5-10 minutes for EC2 instances to boot"
  exit 1
fi
echo ""

# Test 1: Normal transaction
echo "Test 1: Normal Transaction (Low Risk)"
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}/score" \
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
)

if echo "$RESPONSE" | grep -q "risk_score"; then
  echo -e "${GREEN}✓ Test passed${NC}"
  echo "Response: $RESPONSE"
else
  echo -e "${RED}✗ Test failed${NC}"
  echo "Response: $RESPONSE"
fi
echo ""

# Test 2: Suspicious transaction
echo "Test 2: Suspicious Transaction (Medium Risk)"
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}/score" \
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
)

if echo "$RESPONSE" | grep -q "risk_score"; then
  echo -e "${GREEN}✓ Test passed${NC}"
  echo "Response: $RESPONSE"
else
  echo -e "${RED}✗ Test failed${NC}"
  echo "Response: $RESPONSE"
fi
echo ""

# Test 3: High-risk transaction
echo "Test 3: High-Risk Transaction (High Risk)"
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}/score" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "transaction_id": "TEST003",
      "amount": 9999.99,
      "merchant": "CRYPTO_EXCHANGE",
      "location": "Unknown",
      "card_present": false,
      "recent_transaction_count": 25
    }
  }'
)

if echo "$RESPONSE" | grep -q "risk_score"; then
  echo -e "${GREEN}✓ Test passed${NC}"
  echo "Response: $RESPONSE"
else
  echo -e "${RED}✗ Test failed${NC}"
  echo "Response: $RESPONSE"
fi
echo ""

echo "=========================================="
echo "  ✅ All Tests Complete!"
echo "=========================================="
