// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract VaultCore is EvictionAccessControl {
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimed;
    mapping(bytes32 => bool) public usedHashes;

    bytes32 public merkleRoot;
    uint256 public totalVaultValue;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    function deposit() external payable {
        _receiveFunds(msg.sender, msg.value);
    }

    function _receiveFunds(address sender, uint256 amount) internal {
        balances[sender] += amount;
        totalVaultValue += amount;
        emit Deposit(sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function claim(
        bytes32[] calldata proof,
        uint256 amount
    ) external whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.processProof(proof, leaf) == merkleRoot,
            "Invalid Merkle proof"
        );
        require(!claimed[msg.sender], "Already claimed");

        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
    }
}
