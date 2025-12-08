use anchor_lang::accounts::account_info;
//-------------------------------------------------------------------------------
///
/// TASK: Implement the deposit functionality for the on-chain vault
/// 
/// Requirements:
/// - Verify that the user has enough balance to deposit
/// - Verify that the vault is not locked
/// - Transfer lamports from user to vault using CPI (Cross-Program Invocation)
/// - Emit a deposit event after successful transfer
/// 
///-------------------------------------------------------------------------------

use anchor_lang::prelude::*;
use anchor_lang::solana_program::program::invoke;
use anchor_lang::solana_program::system_instruction::transfer;
use crate::state::Vault;
use crate::errors::VaultError;
use crate::events::DepositEvent;

#[derive(Accounts)]
pub struct Deposit<'info> {
    // TODO: Add required accounts and constraints
    #[account(mut)]
    pub user: Signer<'info>,

    #[account(
        mut,
        seeds = [b"vault", vault.vault_authority.as_ref()],
        bump
    )]
    pub vault: Account<'info, Vault>,
    pub system_program: Program<'info, System>,
}

pub fn _deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    // TODO: Implement deposit functionality
    // Verify that the vault is not locked
    if ctx.accounts.vault.locked {
        return Err(VaultError::VaultLocked.into());
    }

    // Verify that the user has enough balance to deposit
    if ctx.accounts.user.lamports() < amount {
        return Err(VaultError::InsufficientBalance.into());
    }

    // Transfer lamports from user to vault using CPI
    let transfer_instruction = transfer(
        &ctx.accounts.user.key(),
        &ctx.accounts.vault.key(),
        amount,
    );

    invoke(
        &transfer_instruction,
        &[
            ctx.accounts.user.to_account_info(),
            ctx.accounts.vault.to_account_info(),
            ctx.accounts.system_program.to_account_info(),
        ],
    )?;

    // Emit deposit event
    emit!(DepositEvent {
        amount,
        user: ctx.accounts.user.key(),
        vault: ctx.accounts.vault.key(),
    });

    Ok(())
}