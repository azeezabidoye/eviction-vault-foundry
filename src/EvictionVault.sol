// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VaultCore.sol";
import "./Timelock.sol";

contract EvictionVault is VaultCore, Timelock {
    constructor(
        address[] memory _owners,
        uint256 _threshold
    ) payable EvictionAccessControl(_owners, _threshold) {
        if (msg.value > 0) {
            _receiveFunds(msg.sender, msg.value);
        }
    }

    receive() external payable {
        _receiveFunds(msg.sender, msg.value);
    }

    function setMerkleRoot(bytes32 root) external onlyVault {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function emergencyWithdrawAll(address payable to) external onlyVault {
        uint256 amount = address(this).balance;
        totalVaultValue = 0;

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function pause() external onlyVault {
        paused = true;
    }

    function unpause() external onlyVault {
        paused = false;
    }
}
