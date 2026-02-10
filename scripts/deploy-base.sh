#!/bin/bash
# Deploy Base/Ethereum Escrow Contracts

set -e

echo "Deploying Base/Ethereum Escrow Contracts..."

# Environment variables (set these before running)
: "${DEPLOYER_PRIVATE_KEY?}"
: "${RPC_URL:=http://127.0.0.1:8545}"
: "${ETHERSCAN_API_KEY?}"

# Project paths
CONTRACTS_DIR="programs/solidity-erc20"
BUILD_DIR="out"

# Install dependencies
echo "Installing dependencies..."
cd "$CONTRACTS_DIR"
forge install
cd - > /dev/null

# Compile contracts
echo "Compiling Solidity contracts..."
forge build --contracts "$CONTRACTS_DIR/contracts" --out "$BUILD_DIR"

# Deploy to Base testnet
echo "Deploying to Base Goerli..."
forge create --rpc-url "$RPC_URL" \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    "$CONTRACTS_DIR/contracts/EscrowFactory.sol:EscrowFactory" \
    --constructor-args "0xYourNFTContract" "0xYourPaymentToken" \
    --verify \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --verifier blockscout

# Deploy to Ethereum mainnet (optional)
read -p "Deploy to Ethereum mainnet? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying to Ethereum mainnet..."
    forge create --rpc-url "https://eth.llamarpc.com" \
        --private-key "$DEPLOYER_PRIVATE_KEY" \
        "$CONTRACTS_DIR/contracts/EscrowFactory.sol:EscrowFactory" \
        --constructor-args "0xYourNFTContract" "0xYourPaymentToken" \
        --verify \
        --etherscan-api-key "$ETHERSCAN_API_KEY"
fi

echo "Deployment complete!"
