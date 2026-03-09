// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract EvictionAccessControl {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;
    bool public paused;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Invalid Owner");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(this), "Only vault can call");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "No owners provided");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "Invalid threshold"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address validOwner = _owners[i];
            require(validOwner != address(0), "Invalid owner address");
            require(!isOwner[validOwner], "Duplicate owner");
            isOwner[validOwner] = true;
            owners.push(validOwner);
        }
        threshold = _threshold;
    }
}
