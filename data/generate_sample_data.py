import json
import random
from datetime import datetime, timedelta

def generate_transaction(is_fraud=False):
    """Generate synthetic transaction data"""
    base_time = datetime.now() - timedelta(days=random.randint(0, 30))
    
    if is_fraud:
        # Fraud patterns
        amount = random.choice([
            random.uniform(500, 5000),  # Large amount
            random.uniform(0.01, 1.0),  # Micro transaction
        ])
        merchants = ["UNKNOWN_MERCHANT", "FOREIGN_SITE", "CRYPTO_EXCHANGE"]
        locations = ["Unknown", "Foreign Country", "High-risk Location"]
        card_present = False
        recent_count = random.randint(5, 20)  # Multiple rapid transactions
    else:
        # Normal patterns
        amount = random.uniform(5, 200)
        merchants = ["Amazon", "Walmart", "Starbucks", "Target", "Gas Station"]
        locations = ["New York", "Los Angeles", "Chicago", "Houston"]
        card_present = random.choice([True, False])
        recent_count = random.randint(0, 3)
    
    return {
        "transaction_id": f"TXN{random.randint(100000, 999999)}",
        "amount": round(amount, 2),
        "merchant": random.choice(merchants),
        "location": random.choice(locations),
        "timestamp": base_time.isoformat(),
        "card_present": card_present,
        "recent_transaction_count": recent_count,
        "is_fraud": is_fraud,
        "confidence": random.uniform(0.85, 0.99)
    }

def generate_dataset(num_samples=1000, fraud_ratio=0.05):
    """Generate training dataset with class imbalance"""
    num_fraud = int(num_samples * fraud_ratio)
    num_normal = num_samples - num_fraud
    
    transactions = []
    
    # Generate fraud transactions
    for _ in range(num_fraud):
        transactions.append(generate_transaction(is_fraud=True))
    
    # Generate normal transactions
    for _ in range(num_normal):
        transactions.append(generate_transaction(is_fraud=False))
    
    random.shuffle(transactions)
    return transactions

if __name__ == "__main__":
    # Generate training data
    print("Generating training dataset...")
    training_data = generate_dataset(num_samples=1000, fraud_ratio=0.05)
    
    with open('data/training/fraud_samples.jsonl', 'w') as f:
        for transaction in training_data:
            f.write(json.dumps(transaction) + '\n')
    
    print(f"Generated {len(training_data)} transactions")
    print(f"Fraud cases: {sum(1 for t in training_data if t['is_fraud'])}")
    print(f"Normal cases: {sum(1 for t in training_data if not t['is_fraud'])}")
    
    # Generate test data
    print("\nGenerating test dataset...")
    test_data = generate_dataset(num_samples=200, fraud_ratio=0.05)
    
    with open('data/test/test_transactions.jsonl', 'w') as f:
        for transaction in test_data:
            f.write(json.dumps(transaction) + '\n')
    
    print(f"Generated {len(test_data)} test transactions")
