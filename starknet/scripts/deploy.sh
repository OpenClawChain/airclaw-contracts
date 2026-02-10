#!/bin/bash
# Deploy Starknet Escrow Contract

set -e

echo "Deploying Starknet Escrow Contract..."

# Environment variables (set these before running)
: "${STARKNET_ACCOUNT_ADDRESS?}"
: "${STARKNET_PRIVATE_KEY?}"
: "${STARKNET_RPC_URL:=http://127.0.0.1:5050}"

# Contract compilation
echo "Compiling Cairo contracts..."
starknet-compile src/escrow.cairo --output escrow.json --abi escrow_abi.json

# Declare contract
echo "Declaring contract..."
starknet declare --contract escrow.json \
    --network alpha-goerli \
    --account_address "$STARKNET_ACCOUNT_ADDRESS" \
    --private_key "$STARKNET_PRIVATE_KEY" \
    --gateway_url "$STARKNET_RPC_URL"

# Deploy contract (requires constructor arguments)
echo "Deploying contract..."
starknet deploy --contract escrow.json \
    --network alpha-goerli \
    --account_address "$STARKNET_ACCOUNT_ADDRESS" \
    --private_key "$STARKNET_PRIVATE_KEY" \
    --gateway_url "$STARKNET_RPC_URL"

echo "Deployment complete!"
