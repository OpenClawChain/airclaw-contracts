# Airclaw Multi-Chain Escrow Contracts

Multi-chain escrow smart contracts for NFT + payment trading across Solana, Starknet, Ethereum/Base, and Sui.

## Quick Start

```bash
# Install dependencies
forge install
npm install -g @solana/cli
cargo install --git https://github.com/starknet-io/starknet-devnet.git
```

## Project Structure

```
airclaw-contracts/
├── programs/
│   ├── solana-anchor/          # Solana escrow (Anchor)
│   │   ├── AirclawEscrow.toml
│   │   └── src/
│   │       └── lib.rs
│   ├── starknet-cairo/         # Starknet escrow (Cairo)
│   │   ├── src/
│   │   │   ├── escrow.cairo
│   │   │   └── interfaces.cairo
│   │   └── tests/
│   ├── solidity-erc20/         # Base/Ethereum escrow (Solidity)
│   │   ├── contracts/
│   │   │   ├── Escrow.sol
│   │   │   └── EscrowFactory.sol
│   │   └── test/
│   └── sui-move/               # Sui escrow (Move)
│       ├── sources/
│       │   ├── escrow.move
│       │   └── escrow_factory.move
│       └── tests/
├── scripts/
│   ├── deploy-starknet.sh
│   └── deploy-base.sh
└── README.md
```

## Supported Chains

### 1. Solana (Anchor)

**Location:** `programs/solana-anchor/`

```bash
# Build
cd programs/solana-anchor
anchor build

# Test
anchor test

# Deploy
anchor deploy --provider.cluster mainnet
```

**Key Features:**
- PDA-based escrow accounts
- Token + SOL exchange
- CPI-based transfers

### 2. Starknet (Cairo)

**Location:** `programs/starknet-cairo/`

```bash
# Compile
starknet-compile src/escrow.cairo --output escrow.json

# Test
pytest tests/

# Deploy
starknet deploy --contract escrow.json
```

**Key Features:**
- ERC721 + ERC20 support
- Dynamic escrow states
- Operator approval pattern

### 3. Ethereum/Base (Solidity)

**Location:** `programs/solidity-erc20/`

```bash
# Build
forge build --contracts programs/solidity-erc20/contracts

# Test
forge test --match-path programs/solidity-erc20/test/*

# Deploy to Base
forge create --rpc-url https://base.llamarpc.com \
    contracts/EscrowFactory.sol:EscrowFactory \
    --constructor-args "0xNFT" "0xTOKEN"
```

**Key Features:**
- OpenZeppelin integration
- Factory pattern for批量 deployment
- ERC721 safe transfers

### 4. Sui (Move)

**Location:** `programs/sui-move/`

```bash
# Build
sui move build

# Test
sui move test

# Publish
sui client publish --gas-budget 100000000
```

**Key Features:**
- Dynamic object fields for NFT storage
- Coin-based payments
- Share objects for global state

## Deployment

### Starknet
```bash
./scripts/deploy-starknet.sh
```

### Base/Ethereum
```bash
./scripts/deploy-base.sh
```

## Security

- All contracts use battle-tested standards
- Reentrancy guards on payment transfers
- Access controls on critical functions
- Event emissions for all state changes

## License

MIT
