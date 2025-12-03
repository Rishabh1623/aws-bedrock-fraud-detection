#!/bin/bash

echo "Setting up Fraud Detection RFT Project..."

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform required but not installed. Aborting." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python 3 required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Node.js required but not installed. Aborting." >&2; exit 1; }

echo "✓ Prerequisites check passed"

# Create Python virtual environment
echo "Creating Python virtual environment..."
cd model
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

echo "✓ Python environment ready"

# Install API dependencies
echo "Installing API dependencies..."
cd api
npm install
cd ..

echo "✓ API dependencies installed"

# Install dashboard dependencies
echo "Installing dashboard dependencies..."
cd dashboard
npm install
cd ..

echo "✓ Dashboard dependencies installed"

# Generate sample data
echo "Generating sample training data..."
cd data
python3 generate_sample_data.py
cd ..

echo "✓ Sample data generated"

echo ""
echo "Setup complete! Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Deploy infrastructure: cd infrastructure && terraform apply"
echo "3. Train model: cd model && python train_rft.py --dataset ../data/training/fraud_samples.jsonl --bucket YOUR_BUCKET"
echo "4. Deploy API: cd api && sam deploy --guided"
echo "5. Start dashboard: cd dashboard && npm run dev"
