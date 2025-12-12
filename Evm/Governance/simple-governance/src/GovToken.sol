// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";     // EIP-2612 gasless approvals
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";      // Voting + delegation + checkpoints
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GovToken - Governance Token with voting and delegation
 * @dev Uses OpenZeppelin ERC20Votes which handles:
 *      - Historical voting power via checkpoints
 *      - Token delegation (users can delegate their votes)
 *      - EIP-2612 permit (sign approvals off-chain)
 */
contract GovToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    // Initial supply: 10,000,000 tokens with 18 decimals
    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 1e18;

    constructor(address owner) 
        ERC20("Governance Token", "GOV") 
        ERC20Permit("Governance Token")
        Ownable(owner)
    {
        _mint(owner, INITIAL_SUPPLY);
    }

    // ============ Required Overrides for ERC20Votes ============

    // The functions below are overrides required by Solidity for multiple inheritance

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    // ============ Optional: Minting control ============

    /// @notice Allows owner to mint new tokens (useful for vesting, incentives, etc.)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyOwner {
        _burn(to, amount);
    }

}