#!/bin/bash
# Deploy Solana Escrow Program

set -e

echo "Deploying Solana Escrow Program..."

# Environment variables
: "${ANCHOR_WALLET?}"
: "${ANCHOR_PROVIDER_URL:=https://api.devnet.solana.com}"
: "${PROGRAM_NAME:=airclaw-escrow}"

# Deploy
echo "Deploying $PROGRAM_NAME to Solana..."
anchor deploy --provider.cluster "$ANCHOR_PROVIDER_URL" --provider.wallet "$ANCHOR_WALLET"

echo "Deployment complete!"
