#!/bin/bash

# Test fraud detection API

API_ENDPOINT="${1:-http://localhost:3000/score}"

echo "Testing Fraud Detection API at $API_ENDPOINT"
echo ""

# Test 1: Normal transaction
echo "Test 1: Normal Transaction"
curl -X POST $API_ENDPOINT \
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
echo -e "\n"

# Test 2: Suspicious transaction
echo "Test 2: Suspicious Transaction"
curl -X POST $API_ENDPOINT \
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
echo -e "\n"

# Test 3: High-risk transaction
echo "Test 3: High-Risk Transaction"
curl -X POST $API_ENDPOINT \
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
echo -e "\n"

echo "Tests complete!"
