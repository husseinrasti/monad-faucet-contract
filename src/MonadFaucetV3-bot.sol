// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {console} from "forge-std/console.sol";

contract MonadFaucetV2 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public owner;
    address public relayer;
    uint256 public dripAmount;
    uint256 public cooldownTime;

    mapping(address => uint256) public lastRequestTime;

    event TokensDripped(address indexed recipient, uint256 amount);
    event CooldownTimeUpdated(uint256 newCooldownTime);
    event DripAmountUpdated(uint256 newDripAmount);
    event RelayerRefunded(address indexed relayer, uint256 gasUsed);

    constructor() payable {
        owner = msg.sender;
        dripAmount = 2 ether; // Default drip amount
        cooldownTime = 3 minutes; // Default cooldown
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Meta-Transaction: Relayer calls this function with user's signature
    function requestTokens(
        address recipient,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(
            address(this).balance >= dripAmount,
            "Not enough funds in the faucet"
        );
        require(
            block.timestamp >= lastRequestTime[recipient] + cooldownTime,
            "Cooldown period has not passed"
        );

        console.log("from signer:");
        console.logAddress(recipient);
        console.logUint(nonce);
        console.logAddress(address(this));
        // Verify recipient's signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(recipient, nonce, address(this))
        );

        address recoveredSigner = messageHash.toEthSignedMessageHash().recover(
            signature
        );
        console.log("signature:");
        console.logBytes32(messageHash);
        console.logBytes(signature);
        console.log("requier equals address:");
        console.logAddress(recoveredSigner);
        console.logAddress(recipient);

        require(recoveredSigner == recipient, "Invalid signature");

        // Update the last request time
        lastRequestTime[recipient] = block.timestamp;

        // Transfer tokens to the recipient
        payable(recipient).transfer(dripAmount);

        emit TokensDripped(recipient, dripAmount);
    }

    // Helper function to recover signer
    function recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        console.logBytes32(ethSignedMessageHash);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        console.logBytes32(r);
        console.logBytes32(s);
        console.logUint(v);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory signature
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");
        assembly ("memory-safe") {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return (r, s, v);
    }

    // Owner can update the drip amount
    function updateDripAmount(uint256 _dripAmount) external onlyOwner {
        dripAmount = _dripAmount;
        emit DripAmountUpdated(_dripAmount);
    }

    // Owner can update the cooldown time
    function updateCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }

    receive() external payable {}

    // Owner can withdraw funds
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough funds");
        payable(owner).transfer(amount);
    }
}
