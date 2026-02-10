#!/bin/bash
# Deploy EVM Escrow Contracts

set -e

echo "Deploying EVM Escrow Contracts..."

# Environment variables
: "${DEPLOYER_PRIVATE_KEY?}"
: "${RPC_URL?}"
: "${ETHERSCAN_API_KEY?}"

# Project paths
CONTRACTS_DIR="evm/contracts"
BUILD_DIR="out"

# Install dependencies
echo "Installing dependencies..."
cd "$CONTRACTS_DIR"
npm install || forge install
cd - > /dev/null

# Compile contracts
echo "Compiling Solidity contracts..."
forge build --contracts "$CONTRACTS_DIR" --out "$BUILD_DIR"

# Deploy contracts
echo "Deploying EscrowFactory..."
forge create --rpc-url "$RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    "$CONTRACTS_DIR/EscrowFactory.sol:EscrowFactory" \
    --constructor-args "0xYourNFTContract" "0xYourPaymentToken"

echo "Deployment complete!"
