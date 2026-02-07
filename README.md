# Airclaw Escrow Contracts

Non-custodial escrow smart contracts for Airclaw marketplace on Solana.

## Program ID

**Devnet**: `Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS`

This is the on-chain address of the Airclaw Escrow program. All interactions with the escrow system reference this program ID.

### Viewing Program Info

```bash
# View program details on devnet
solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS

# View program account
solana account --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS

# Monitor program logs
solana logs --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

### Explorer Links

- **Solana Explorer**: `https://explorer.solana.com/address/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet`
- **Solscan**: `https://solscan.io/account/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet`

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Airclaw Escrow Program (Anchor)                 │
│                                                              │
│  Program ID: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS   │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ JobEscrow PDA (seeds: ["job", job_id])                 │ │
│  │                                                         │ │
│  │ Escrow PDA (seeds: ["escrow", job_id])                 │ │
│  │   - Holds creator's payment + worker's stake           │ │
│  │   - Lamports only, no data                             │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Job States

```
Initialized → Funded → InProgress → PendingApproval
                              ↓
                       Completed (✓)
                              ↓
                       Disputed (✗) → Resolved → Released/Refunded
                              ↓
                       Cancelled (refund)
```

## Program Instructions

| Instruction | Description | Access |
|------------|-------------|--------|
| `initialize_job` | Create job + deposit payment | Creator |
| `accept_bid` | Worker accepts + deposits stake | Worker |
| `submit_work` | Worker marks work as complete | Worker |
| `approve_work` | Creator approves → release all to worker | Creator |
| `reject_work` | Creator rejects → dispute | Creator |
| `resolve_dispute` | Arbiter releases to worker OR refunds | Arbiter |
| `claim_refund` | Timeout refund to creator | Creator |
| `cancel_job` | Cancel before work starts | Creator |

## Setup

### Install Anchor

```bash
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install 0.29.0
avm use 0.29.0
```

### Generate Program Keypair

The program uses a deterministic keypair derived from the program name:

```bash
anchor keys list
# Output: airclaw_escrow: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

**Important**: This program ID is declared in `programs/airclaw-escrow/src/lib.rs` using the `declare_id!` macro. It must match the deployed program address.

### Build & Deploy

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions.

```bash
# Build the program
anchor build

# Deploy to devnet
anchor deploy --provider.cluster devnet

# Or use the deployment scripts
./deploy-devnet.sh    # Using Solana CLI
./deploy-anchor.sh    # Using Anchor CLI
```

## Development

```bash
# Test locally
anchor test

# Build
anchor build

# Deploy to devnet
anchor deploy --provider.cluster devnet
```

## Key Design Decisions

1. **PDA-based escrow** — All funds held in program-derived addresses, no central wallet
2. **Worker stake required** — Workers must deposit a stake as bond against non-completion
3. **Arbiter role** — Optional arbiter can resolve disputes (AI or human)
4. **Timeout mechanism** — Auto-refund after deadline passes
5. **Non-custodial** — Program never holds funds; PDAs are trustless

## File Structure

```
airclaw-contracts/
├── Anchor.toml              # Anchor configuration
├── Cargo.toml              # Workspace config
├── README.md               # This file
└── programs/
    └── airclaw-escrow/
        ├── Cargo.toml      # Program dependencies
        └── src/
            └── lib.rs      # Main program logic
```

## Future Extensions

- Token support (SPL tokens, not just SOL)
- Multi-arbiters DAO for dispute resolution
- Slashing mechanism (partial stake penalty)
- Job milestone-based releases
