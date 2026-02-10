# Anchor Program Deployment

## Prerequisites

### 1. Install Solana Toolchain
```bash
# Using Solana installer
curl -sSfL https://release.solana.com/v1.18.0/install | sh

# Add to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Verify
solana --version
```

### 2. Configure for Devnet
```bash
solana config set --url devnet
solana config get
```

### 3. Ensure Wallet has SOL
```bash
# Check balance
solana balance

# Airdrop if needed
solana airdrop 2
```

## Build & Deploy

### Option A: Using Anchor
```bash
cd /Users/peterclaw/.openclaw/workspace/airclaw-contracts

# Build (requires anchor-cli >= 0.29.0)
anchor build

# Deploy
anchor deploy --provider.cluster devnet
```

### Option B: Using Solana CLI (if anchor build fails)
```bash
cd /Users/peterclaw/.openclaw/workspace/airclaw-contracts

# Build with cargo
cargo build-sbf --manifest-path=programs/airclaw-escrow/Cargo.toml

# Deploy
solana program deploy \
  --url devnet \
  target/deploy/airclaw_escrow.so
```

## Update Program ID

After deployment, copy the new program ID and update:

1. `/Users/peterclaw/.openclaw/workspace/airclaw-contracts/programs/airclaw-escrow/src/lib.rs`:
```rust
declare_id!("YOUR_NEW_PROGRAM_ID");
```

2. `/Users/peterclaw/.openclaw/workspace/airclaw-api/src/escrow/solana-escrow.service.ts`:
```typescript
const PROGRAM_ID = new PublicKey('YOUR_NEW_PROGRAM_ID');
```

3. `/Users/peterclaw/.openclaw/workspace/airclaw-api/src/env.ts`:
```typescript
SOLANA_PROGRAM_ID: z.string().default('YOUR_NEW_PROGRAM_ID'),
```

## Current Status

| Component | Status |
|-----------|--------|
| Anchor Program Code | ✅ Written |
| Build Tools | ❌ Not installed |
| Deployment | ❌ Pending |
| API Integration | ✅ Ready |

## Quick Deploy When Tools Available

```bash
# Set PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Build
cd /Users/peterclaw/.openclaw/workspace/airclaw-contracts
cargo build-sbf --manifest-path=programs/airclaw-escrow/Cargo.toml

# Deploy
solana program deploy \
  --url devnet \
  target/deploy/airclaw_escrow.so

# Copy program ID from output
```

## Current Program ID (placeholder)
```
Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```
