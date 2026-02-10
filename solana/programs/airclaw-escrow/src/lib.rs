#[program]
pub mod airclaw_escrow {
    use super::*;

    /// Initialize a new escrow
    pub fn initialize(
        ctx: Context<Initialize>,
        seed: u64,
        maker: Pubkey,
        taker: Pubkey,
        mint: Pubkey,
        amount: u64,
        price: u64,
    ) -> Result<()> {
        let escrow = &mut ctx.accounts.escrow;
        escrow.seed = seed;
        escrow.maker = maker;
        escrow.taker = taker;
        escrow.mint = mint;
        escrow.amount = amount;
        escrow.price = price;
        escrow.bump = ctx.bumps.escrow;
        
        Ok(())
    }

    /// Cancel escrow and return tokens to maker
    pub fn cancel(ctx: Context<Cancel>) -> Result<()> {
        let escrow = &mut ctx.accounts.escrow;
        **escrow.to_account_info().try_borrow_mut_lamports()? -= escrow.amount;
        **ctx.accounts.maker.lamports.borrow_mut() += escrow.amount;
        
        Ok(())
    }

    /// Execute escrow - exchange tokens for SOL
    pub fn execute(ctx: Context<Execute>, amount: u64) -> Result<()> {
        let escrow = &mut ctx.accounts.escrow;
        
        // Transfer tokens from escrow to taker
        let cpi_accounts = Transfer {
            from: ctx.accounts.escrow.to_account_info(),
            to: ctx.accounts.taker_ata.to_account_info(),
            authority: ctx.accounts.escrow.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let bump = &[escrow.bump];
        let signer = &[&[&[b"escrow", escrow.maker.as_ref(), &escrow.seed.to_le_bytes(), bump]]];
        let cpi_ctx = CpiContext::new_with_signer(cpi_program, cpi_accounts, signer);
        token::transfer(cpi_ctx, amount)?;

        // Transfer SOL from taker to maker
        **ctx.accounts.taker.lamports.borrow_mut() -= escrow.price;
        **ctx.accounts.maker.lamports.borrow_mut() += escrow.price;

        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = maker,
        space = Escrow::LEN,
        seeds = [b"escrow", maker.key().as_ref(), seed.to_le_bytes().as_ref()],
        bump
    )]
    pub escrow: Account<'info, Escrow>,
    #[account(mut)]
    pub maker: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Cancel<'info> {
    #[account(mut, close = maker, has_one = maker)]
    pub escrow: Account<'info, Escrow>,
    #[account(mut)]
    pub maker: SystemAccount<'info>,
}

#[derive(Accounts)]
pub struct Execute<'info> {
    #[account(mut, has_one = taker, has_one = mint)]
    pub escrow: Account<'info, Escrow>,
    #[account(mut)]
    pub taker: Signer<'info>,
    #[account(mut)]
    pub maker: SystemAccount<'info>,
    #[account(mut)]
    pub taker_ata: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}

#[account]
pub struct Escrow {
    pub seed: u64,
    pub maker: Pubkey,
    pub taker: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
    pub price: u64,
    pub bump: u8,
}

impl Escrow {
    pub const LEN: usize = 8 + 8 + 32 + 32 + 32 + 8 + 8 + 1;
}
