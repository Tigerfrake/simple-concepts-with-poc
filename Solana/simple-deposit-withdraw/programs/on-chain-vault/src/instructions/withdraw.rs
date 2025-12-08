//-------------------------------------------------------------------------------
///
/// TASK: Implement the withdraw functionality for the on-chain vault
/// 
/// Requirements:
/// - Verify that the vault is not locked
/// - Verify that the vault has enough balance to withdraw
/// - Transfer lamports from vault to vault authority
/// - Emit a withdraw event after successful transfer
/// 
///-------------------------------------------------------------------------------

use anchor_lang::prelude::*;
use crate::state::Vault;
use crate::errors::VaultError;
use crate::events::WithdrawEvent;

#[derive(Accounts)]
pub struct Withdraw<'info> {
    // TODO: Add required accounts and constraints
    #[account(mut)]
    pub vault_authority: Signer<'info>,

    #[account(
        mut,
        seeds = [b"vault", vault_authority.key().as_ref()],
        bump,
        has_one = vault_authority
    )]
    pub vault: Account<'info, Vault>,
    pub system_program: Program<'info, System>,
}

pub fn _withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // TODO: Implement withdraw functionality
    // Verify that the vault is not locked
    if ctx.accounts.vault.locked {
        return Err(VaultError::VaultLocked.into());
    }

    // Get the vault account info to check lamports
    let vault_account_info = &ctx.accounts.vault.to_account_info();
    
    // Calculate available balance (total lamports minus rent exemption)
    let rent = Rent::get()?;
    let min_rent = rent.minimum_balance(vault_account_info.data_len());
    let available_balance = vault_account_info.lamports().checked_sub(min_rent)
        .ok_or(VaultError::InsufficientBalance)?;

    // Verify that the vault has enough available balance to withdraw
    if available_balance < amount {
        return Err(VaultError::InsufficientBalance.into());
    }

    // Transfer lamports from PDA vault to vault authority
    **vault_account_info.try_borrow_mut_lamports()? = vault_account_info
        .lamports()
        .checked_sub(amount)
        .ok_or(VaultError::Overflow)?;

    **ctx.accounts.vault_authority.try_borrow_mut_lamports()? = ctx.accounts.vault_authority
        .lamports()
        .checked_add(amount)
        .ok_or(VaultError::Overflow)?;
    
    // Emit withdraw event
    emit!(WithdrawEvent {
        amount,
        vault_authority: ctx.accounts.vault_authority.key(),
        vault: ctx.accounts.vault.key(),
    });

    Ok(())
}