// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

abstract contract TimelockManager is EvictionAccessControl {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;
    uint256 public txCount;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner whenNotPaused {
        uint256 id = txCount++;

        uint256 execTime = 0;
        if (threshold == 1) {
            execTime = block.timestamp + TIMELOCK_DURATION;
        }

        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: execTime
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external onlyOwner whenNotPaused {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Transaction already executed");
        require(
            !confirmed[txId][msg.sender],
            "Transaction already confirmed by this owner"
        );

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold && txn.executionTime == 0) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "Not enough confirmations");
        require(!txn.executed, "Transaction already executed");
        require(txn.executionTime > 0, "Timelock not started");
        require(block.timestamp >= txn.executionTime, "Timelock not expired");

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction execution failed");

        emit Execution(txId);
    }
}
