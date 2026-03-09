# Eviction Vault Test Project

## Overview

This project is a refactoring of the `EvictionVault.sol` smart contract, which was previously a single-file application with major vulnerabilities.

## Refactoring Structure

The codebase was modularized to increase maintainability, follow best practices, and implement safe architectural principles. The logic is now separated into various parts:

- `EvictionVault.sol` - Main entrypoint and composition
- `VaultCore.sol` - Core vault operations like deposit, withdrawal, claiming
- `Timelock.sol` - Multisig and timelock transaction management
- `AccessControl.sol` - Ownership and pause controls

## Addressed Security Issues

1. **Unrestricted `setMerkleRoot`:**
   Anyone could call `setMerkleRoot`. This was corrected by introducing `onlyVault` modifier. It can now only be called through a multisig proposal.
2. **Public `emergencyWithdrawAll`:**
   The function allowed anyone to drain the contract. Corrected by applying the `onlyVault` modifier and changing the receiver to a specific address passed in the transaction proposal, instead ofthe `msg.sender`.
3. **Centralized Pause Control:**
   Initially, the system could be paused by a single owner, causing risk of centralization. Rewritten to only be accessible via `onlyVault`, moving the pause action to a multisig and timelock process.
4. **Unsafe implementation of `receive()`:**
   The fallback function relied on `tx.origin`. Now uses `msg.sender`, and accurately tracking user deposits based on caller logic.
5. **Unsafe use of `.transfer`:**
   Withdraw and claim operations utilized the insecure `.transfer()` gas-limited function. This has been entirely replaced with `.call{value: amount}("")` along with comprehensive success verifications.
6. **Timelock Execution Bypass:**
   The original contract permitted bypassing the timelock when `threshold` was set to 1. The delay calculation has been refactored to explicitly ensure the delay and expiration bounds even if `threshold == 1`.
