// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault vault;

    address owner1 = address(0x101);
    address owner2 = address(0x102);
    address owner3 = address(0x103);

    address[] owners;

    address user1 = address(0x201);
    address user2 = address(0x202);

    function setUp() public {
        vm.deal(user1, 10e18);
        vm.deal(user2, 10e18);
        vm.deal(owner1, 10e18);

        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);

        vault = new EvictionVault(owners, 2);
    }

    // 1. Authorized users can update the Merkle root via multisig
    function test_AuthorizedUsersCanUpdateMerkleRoot() public {
        bytes32 newRoot = keccak256("newRoot");
        bytes memory data = abi.encodeWithSignature(
            "setMerkleRoot(bytes32)",
            newRoot
        );

        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, data);
        uint256 txId = vault.txCount() - 1;

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        // Advance block timestamp across the execution time
        vm.warp(block.timestamp + vault.TIMELOCK_DURATION() + 1);

        vault.executeTransaction(txId);

        assertEq(vault.merkleRoot(), newRoot);
    }

    // 2. Unauthorized users cannot call restricted functions
    function test_RevertIf_UnauthorizedUserCannotUpdateMerkleRoot() public {
        bytes32 newRoot = keccak256("newRoot");

        vm.prank(user1);
        vm.expectRevert("Only vault can call");
        vault.setMerkleRoot(newRoot);
    }

    // 3. Withdrawals work correctly
    function test_WithdrawalsWorkCorrectly() public {
        uint256 depositAmt = 1e18;

        vm.prank(user1);
        vault.deposit{value: depositAmt}();

        assertEq(vault.balances(user1), depositAmt);

        uint256 initialBal = user1.balance;

        vm.prank(user1);
        vault.withdraw(depositAmt);

        assertEq(vault.balances(user1), 0);
        assertEq(user1.balance, initialBal + depositAmt);
    }

    // 4. Timelock protections function properly
    function test_RevertIf_ExecuteTransactionBeforeTimelockExpires() public {
        bytes32 newRoot = keccak256("newRoot");
        bytes memory data = abi.encodeWithSignature(
            "setMerkleRoot(bytes32)",
            newRoot
        );

        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, data);
        uint256 txId = vault.txCount() - 1;

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        // Do not warp time, so the timelock hasn't expired

        vm.expectRevert("Timelock not expired");
        vault.executeTransaction(txId);
    }

    // 5. Pause controls work
    function test_PauseControlsWork() public {
        bytes memory data = abi.encodeWithSignature("pause()");

        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, data);
        uint256 txId = vault.txCount() - 1;

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        vm.warp(block.timestamp + vault.TIMELOCK_DURATION() + 1);

        vault.executeTransaction(txId);

        assertTrue(vault.paused());

        // Test pausing prevents withdrawal
        vm.prank(user1);
        vault.deposit{value: 1e18}();

        vm.expectRevert("Contract is paused");
        vm.prank(user1);
        vault.withdraw(1 ether);
    }

    // 6. Emergency withdraw works via authorized workflow
    function test_EmergencyWithdrawAll() public {
        vm.prank(user1);
        vault.deposit{value: 5e18}();

        vm.prank(user2);
        vault.deposit{value: 4e18}();

        address payable testReceiver = payable(address(0x999));

        bytes memory data = abi.encodeWithSignature(
            "emergencyWithdrawAll(address)",
            testReceiver
        );

        vm.prank(owner1);
        vault.submitTransaction(address(vault), 0, data);
        uint256 txId = vault.txCount() - 1;

        vm.prank(owner2);
        vault.confirmTransaction(txId);

        vm.warp(block.timestamp + vault.TIMELOCK_DURATION() + 1);

        vault.executeTransaction(txId);

        assertEq(testReceiver.balance, 9e18);
        assertEq(vault.totalVaultValue(), 0);
    }
}
