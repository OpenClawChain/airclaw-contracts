# airclaw-contracts

Solana-first on-chain components for **Airclaw**.

## MVP note (custodial escrow)
For the hackathon/devnet MVP we are using **custodial escrow**:

- Funds are held in an Airclaw-controlled Solana wallet (signed server-side via AgentWallet)
- The API tracks escrow state in the DB
- Release/refund is performed by the API as System Program SOL transfers

This keeps the MVP shippable fast while we iterate on product + UX.

## Roadmap (non-custodial)
Later we can add a proper on-chain escrow program (Anchor or native Solana program) for:

- Non-custodial escrow accounts (PDA-controlled)
- On-chain arbitration / milestones
- SPL token support (USDC etc.)

## Repo layout
- `solana/` (planned): escrow program + TS client
