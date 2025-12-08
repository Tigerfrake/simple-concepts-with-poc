## Fundamental Concept
In a normal contract:
```solidity
Contract Address = Code + Storage
```
In an upgradeable system:
```solidity
Proxy Address  → holds ALL storage
Implementation → holds ONLY code
```
Execution flow:
```solidity
User → Proxy → delegatecall → Implementation
// Code is swappable. Storage is permanent.
```

## `delegatecall` (The Mechanical Core)

When a proxy uses delegatecall:
- msg.sender stays the original caller
- msg.value stays the original value
- Storage writes happen in the proxy
- Implementation storage is never used
- `address(this)` becomes the proxy address
So the implementation behaves as if it lives at the proxy address, even though only its code is executed.
This is why:
- State survives upgrades
- But storage layout MUST remain compatible forever

## Why Constructors Don’t Work
Constructors run on the implementation contract, not the proxy.
But:
- Users never interact with the implementation
- They only interact with the proxy
- And the proxy has no constructor logic from the implementation
Therefore:
```solidity
constructor()  →  WRONG
initialize()   →  CORRECT
```
Initialization must be:
- External
- Run once
- Protected against re-execution

## The Initialization Phase
Initialization is when:
- Owner is set
- Roles are assigned
- Core parameters are locked
This is the most dangerous moment in the system’s lifetime.

Failure modes:
- Proxy deployed without initialization → first caller takes ownership
- Initialization callable twice → takeover
- Wrong sender → permanent loss of admin

## The Upgrade Process (What Actually Changes)
An upgrade does only one thing at the protocol level:
```solidity
Change the implementation pointer stored in proxy storage
```

## Storage Layout Rules (The Golden Law)
Across all upgrades:
- You may append new variables
- You must NOT reorder
- You must NOT delete
- You must NOT change types
- You must NOT change inheritance order

Reason:
- Storage slots are positional
- slot 0 today must mean the same thing forever

Violation consequence:
- Silent corruption
- Permanent fund loss
- No recovery possible

## Why Access Control Is Central to Upgradeability
Upgradeability introduces a god-mode permission:
- Whoever can upgrade can arbitrarily change all contract behavior.

Therefore:
- Upgrade authority must be extremely protected
- Ownership mistakes are catastrophic
- Losing the upgrade key = irreversible lock
- Compromised upgrade key = total protocol takeover

This is why:
- Multisigs are used
- Timelocks are used

On-chain governance is use
```solidity
```
```solidity
```