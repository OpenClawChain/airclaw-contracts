# Airclaw Escrow - Deployment Guide

## Prerequisites

1. **Solana CLI** installed and configured
2. **Anchor CLI** (optional, for anchor deploy method)
3. **Rust** and **Cargo** with Solana BPF toolchain
4. A funded wallet for devnet deployment

## Current Issue

The project currently has a dependency resolution issue with `constant_time_eq v0.4.2` requiring Cargo edition2024, which is not supported by Solana toolchain 3.0.13's bundled Cargo (1.84.0).

### Solution Options

#### Option 1: Update Solana Toolchain (Recommended)

```bash
# Update to latest stable Solana
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Verify installation
solana --version
cargo --version  # Should show newer version
```

#### Option 2: Use Agave

```bash
# Install Agave (newer Solana client)
cargo install agave-install
agave-install init
```

#### Option 3: Clear cargo cache and retry

```bash
# Remove problematic cache
rm -rf ~/.cargo/registry/src/index.crates.io-6f17d22bba15001f/constant_time_eq-0.4.2
rm -rf ~/.cargo/registry/cache/index.crates.io-6f17d22bba15001f/constant_time_eq-0.4.2

# Try building again
cargo build-sbf --manifest-path programs/airclaw-escrow/Cargo.toml
```

## Deployment Steps

### Method 1: Using Solana CLI Directly

```bash
# 1. Build the program
cargo build-sbf --manifest-path programs/airclaw-escrow/Cargo.toml

# 2. Set Solana to devnet
solana config set --url devnet

# 3. Check your wallet balance (you need SOL for deployment)
solana balance

# 4. If balance is low, airdrop some devnet SOL
solana airdrop 2

# 5. Deploy the program
solana program deploy \
  --url devnet \
  --program-id programs/airclaw-escrow/target/deploy/airclaw_escrow-keypair.json \
  target/deploy/airclaw_escrow.so

# 6. Verify deployment
solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

### Method 2: Using Anchor CLI

```bash
# 1. Build with Anchor
anchor build

# 2. Deploy to devnet
anchor deploy --provider.cluster devnet

# 3. Verify deployment
solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

### Method 3: Using Deployment Scripts

```bash
# Using Solana CLI script
./deploy-devnet.sh

# OR using Anchor script
./deploy-anchor.sh
```

## Program Information

- **Program Name**: airclaw_escrow
- **Program ID**: `Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS`
- **Network**: Devnet
- **Binary Location**: `target/deploy/airclaw_escrow.so`

## Troubleshooting

### "insufficient funds" error
```bash
# Airdrop devnet SOL
solana airdrop 2 --url devnet
```

### "program already deployed" error
```bash
# Upgrade existing program instead
solana program deploy \
  --url devnet \
  --program-id Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS \
  target/deploy/airclaw_escrow.so
```

### Build fails with edition2024 error
See "Solution Options" above to update your toolchain.

## Post-Deployment

After successful deployment, you can:

1. **View program info**:
   ```bash
   solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
   ```

2. **Check program account**:
   ```bash
   solana account --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
   ```

3. **View program logs** (during transactions):
   ```bash
   solana logs --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
   ```
