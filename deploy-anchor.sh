#!/bin/bash

# Airclaw Escrow - Deploy using Anchor CLI

set -e

echo "🔨 Building with Anchor..."
anchor build

echo "✅ Build complete!"
echo ""

# Check Solana config
echo "🔍 Checking Solana configuration..."
solana config get

echo ""
echo "💰 Checking wallet balance..."
solana balance --url devnet

echo ""
read -p "Deploy to devnet? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🚀 Deploying to devnet with Anchor..."
    anchor deploy --provider.cluster devnet
    
    echo ""
    echo "✅ Deployment complete!"
    echo "Program ID: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
    echo ""
    echo "Verify deployment:"
    echo "  solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
else
    echo "Deployment cancelled."
fi
