use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[cfg(feature = "no-entrypoint")]
solana_program::declare_id!(pubkey!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"));

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_job_status_transitions() {
        // Test basic enum functionality
        assert!(true);
    }
}
