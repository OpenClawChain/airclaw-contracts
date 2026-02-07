# Airclaw Escrow Program ID Reference

## Program Identifier

```
Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

## Network Deployments

| Network | Program ID | Status | Explorer |
|---------|-----------|--------|----------|
| **Devnet** | `Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS` | 🟡 Pending | [View on Explorer](https://explorer.solana.com/address/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet) |
| **Mainnet** | TBD | ⚪ Not Deployed | - |

## Program Details

- **Name**: `airclaw_escrow`
- **Framework**: Anchor v0.29.0
- **Language**: Rust
- **Type**: Escrow / Payment Protocol

## Keypair Location

The program keypair is generated during the build process and stored at:
```
target/deploy/airclaw_escrow-keypair.json
```

⚠️ **Security Note**: Keep this keypair secure. It's required to upgrade the program after deployment.

## Verification

### Check if Program is Deployed

```bash
# Devnet
solana program show --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS

# Expected output if deployed:
# Program Id: Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
# Owner: BPFLoaderUpgradeab1e11111111111111111111111
# ProgramData Address: <address>
# Authority: <your wallet>
# Last Deployed In Slot: <slot>
# Data Length: <bytes>
```

### Verify Program Hash

```bash
# Get deployed program hash
solana program dump --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS deployed.so
sha256sum deployed.so

# Compare with local build
sha256sum target/deploy/airclaw_escrow.so
```

## Usage in Client Code

### JavaScript/TypeScript (Anchor)

```typescript
import { Program, AnchorProvider } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";

const PROGRAM_ID = new PublicKey("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

// Load program
const program = new Program(idl, PROGRAM_ID, provider);
```

### Rust

```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod airclaw_escrow {
    use super::*;
    // Your program logic
}
```

### Python (Anchorpy)

```python
from solana.publickey import PublicKey
from anchorpy import Program, Provider

PROGRAM_ID = PublicKey("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS")

# Load program
program = await Program.at(PROGRAM_ID, provider)
```

## Program Derived Addresses (PDAs)

The program uses the following PDA seeds:

### Job Escrow Account
```
Seeds: ["job", job_id: [u8; 32]]
Purpose: Stores job metadata and state
```

### Escrow Vault
```
Seeds: ["escrow", job_id: [u8; 32]]
Purpose: Holds escrowed funds (SOL)
```

### Example PDA Derivation (TypeScript)

```typescript
import { PublicKey } from "@solana/web3.js";

const PROGRAM_ID = new PublicKey("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");
const jobId = Buffer.from("your-job-id-32-bytes");

// Derive Job Escrow PDA
const [jobEscrowPda, jobBump] = PublicKey.findProgramAddressSync(
  [Buffer.from("job"), jobId],
  PROGRAM_ID
);

// Derive Escrow Vault PDA
const [escrowVaultPda, vaultBump] = PublicKey.findProgramAddressSync(
  [Buffer.from("escrow"), jobId],
  PROGRAM_ID
);
```

## Monitoring

### View Recent Transactions

```bash
# View program logs in real-time
solana logs --url devnet Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS
```

### Explorer Links

- **Solana Explorer (Devnet)**: https://explorer.solana.com/address/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet
- **Solscan (Devnet)**: https://solscan.io/account/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet
- **SolanaFM (Devnet)**: https://solana.fm/address/Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS?cluster=devnet-solana

## Upgrade Authority

After deployment, the program upgrade authority is set to the deploying wallet. To transfer authority:

```bash
# Transfer to new authority
solana program set-upgrade-authority \
  --url devnet \
  Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS \
  --new-upgrade-authority <NEW_AUTHORITY_PUBKEY>

# Make program immutable (cannot be upgraded)
solana program set-upgrade-authority \
  --url devnet \
  Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS \
  --final
```

## Security Considerations

1. **Keypair Storage**: The program keypair in `target/deploy/` should be backed up securely
2. **Upgrade Authority**: Consider using a multisig for mainnet upgrade authority
3. **Audit**: Program should be audited before mainnet deployment
4. **Immutability**: Consider making the program immutable after thorough testing

## Support

For issues or questions about this program:
- GitHub Issues: [Your repo URL]
- Documentation: See [README.md](./README.md) and [DEPLOYMENT.md](./DEPLOYMENT.md)
