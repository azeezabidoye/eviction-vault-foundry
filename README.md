# Eviction Vault Test Project

## Overview

This project is a refactoring of the `EvictionVault.sol` smart contract, which was previously a single-file application with major vulnerabilities.

## Refactoring Structure

The codebase was modularized to increase maintainability, follow best practices, and implement safe architectural principles. The logic is now separated into various parts:

- `EvictionVault.sol` - Main entrypoint and composition
- `VaultCore.sol` - Core vault operations like deposit, withdrawal, claiming
- `Timelock.sol` - Multisig and timelock transaction management
- `AccessControl.sol` - Ownership and pause controls
