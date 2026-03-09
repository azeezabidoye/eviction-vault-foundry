# EvictionVault Refactoring

This project is a refactor of the `EvictionVault.sol` smart contract, which was originally a single-file application with several critical security vulnerabilities.

## Refactoring Overview

The codebase was modularized to improve maintainability, follow best practices, and introduce safe architectural patterns. The logic is now divided into distinct parts:

- `EvictionVault.sol` (Main entrypoint and composition)
- `VaultCore.sol` (Core vault operations like deposit, withdrawal, claiming)
- `TimelockManager.sol` (Multisig and timelock transaction management)
- `AccessControl.sol` (Ownership and pause controls)
