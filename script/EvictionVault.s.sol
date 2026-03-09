// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EvictionVault.sol";

contract DeployEvictionVault is Script {
    function run() public {
        vm.startBroadcast();

        address[] memory owners = new address[](3);
        owners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        owners[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        owners[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        new EvictionVault(owners, 2);

        vm.stopBroadcast();
    }
}
