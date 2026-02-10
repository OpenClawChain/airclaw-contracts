#!/bin/bash
# Deploy Sui Escrow Contracts

set -e

echo "Deploying Sui Escrow Contracts..."

# Environment variables
: "${SUI_RPC_URL:=http://127.0.0.1:9000}"
: "${SUI_PRIVATE_KEY?}"
: "${GAS_BUDGET:=100000000}"

# Build
echo "Building Move contracts..."
sui move build --path sui/sources

# Deploy
echo "Deploying Escrow module..."
sui client publish --path sui/sources \
    --gas-budget "$GAS_BUDGET" \
    --json

echo "Deployment complete!"
