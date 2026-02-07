#!/bin/bash

# Airclaw Escrow - Deploy to Devnet Script

set -e

echo "🔨 Building Solana program..."
cargo build-sbf --manifest-path programs/airclaw-escrow/Cargo.toml

echo "✅ Build complete!"
echo ""
echo "📋 Program details:"
echo "  Name: airclaw_escrow"
echo "  Program ID: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
echo "  Binary: target/deploy/airclaw_escrow.so"
echo ""

# Check Solana config
echo "🔍 Checking Solana configuration..."
solana config get

echo ""
echo "💰 Checking wallet balance..."
solana balance

echo ""
read -p "Deploy to devnet? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🚀 Deploying to devnet..."
    solana program deploy \
        --url devnet \
        --program-id programs/airclaw-escrow/target/deploy/airclaw_escrow-keypair.json \
        target/deploy/airclaw_escrow.so
    
    echo ""
    echo "✅ Deployment complete!"
    echo "Program ID: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
    echo ""
    echo "Verify deployment:"
    echo "  solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
else
    echo "Deployment cancelled."
fi
