// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {MonadFaucet} from "../src/MonadFaucet.sol";

contract MonadFaucetTest is Test {
    MonadFaucet faucet;

    uint256 internal recipientPrivateKey;
    uint256 internal ownerPrivateKey;
    uint256 internal relayerPrivateKey;

    address owner;
    address relayer;
    address recipient;

    // Setup function to deploy the contract and initialize addresses
    function setUp() public {
        recipientPrivateKey = 0xa11ce;
        ownerPrivateKey = 0xabc123;
        relayerPrivateKey = 0x123abc;

        owner = vm.addr(ownerPrivateKey);
        recipient = vm.addr(recipientPrivateKey);
        relayer = vm.addr(relayerPrivateKey);

        // Deploy the contract with the relayer address
        vm.prank(owner);
        faucet = new MonadFaucet(relayer);

        // Fund the contract with some ETH
        vm.deal(address(faucet), 10 ether);
    }

    // Test the constructor
    function testConstructor() public {
        assertEq(faucet.owner(), owner, "Owner should be set correctly");
        assertEq(faucet.relayer(), relayer, "Relayer should be set correctly");
        assertEq(faucet.dripAmount(), 1 ether, "Drip amount should be 1 ether");
        assertEq(
            faucet.cooldownTime(),
            1 minutes,
            "Cooldown time should be 1 minute"
        );
    }

    // Test updating the relayer address
    function testUpdateRelayer() public {
        address newRelayer = address(0xABC);

        // Only owner can update the relayer
        vm.prank(owner);
        faucet.updateRelayer(newRelayer);

        assertEq(faucet.relayer(), newRelayer, "Relayer should be updated");

        // Non-owner cannot update the relayer
        vm.prank(recipient);
        vm.expectRevert("Only owner can call this function");
        faucet.updateRelayer(newRelayer);
    }

    // Test requesting tokens with a valid signature from the relayer
    function testRequestTokens() public {
        // Prepare the message and signature
        bytes32 messageHash = keccak256(abi.encodePacked(recipient));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            relayerPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Request tokens as the relayer
        vm.prank(relayer);
        faucet.requestTokens(recipient, signature);

        // Check that the user received the tokens
        assertEq(recipient.balance, 1 ether, "User should receive 1 ether");
        assertEq(
            faucet.lastRequestTime(recipient),
            block.timestamp,
            "Last request time should be updated"
        );
    }

    // Test requesting tokens with an invalid signature
    function testRequestTokensInvalidSignature() public {
        // Prepare an invalid signature (signed by a non-relayer)
        bytes32 messageHash = keccak256(abi.encodePacked(recipient));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            recipientPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Attempt to request tokens as the relayer
        vm.prank(relayer);
        vm.expectRevert("Invalid signature");
        faucet.requestTokens(recipient, signature);
    }

    // Test requesting tokens without being the relayer
    function testRequestTokensNotRelayer() public {
        // Prepare the message and signature
        bytes32 messageHash = keccak256(abi.encodePacked(recipient));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            relayerPrivateKey,
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Attempt to request tokens as a non-relayer
        vm.prank(recipient);
        vm.expectRevert("Only relayer can call this function");
        faucet.requestTokens(recipient, signature);
    }

    // Test updating the drip amount
    function testUpdateDripAmount() public {
        uint256 newDripAmount = 2 ether;

        // Only owner can update the drip amount
        vm.prank(owner);
        faucet.updateDripAmount(newDripAmount);

        assertEq(
            faucet.dripAmount(),
            newDripAmount,
            "Drip amount should be updated"
        );

        // Non-owner cannot update the drip amount
        vm.prank(recipient);
        vm.expectRevert("Only owner can call this function");
        faucet.updateDripAmount(newDripAmount);
    }

    // Test updating the cooldown time
    function testUpdateCooldownTime() public {
        uint256 newCooldownTime = 2 minutes;

        // Only owner can update the cooldown time
        vm.prank(owner);
        faucet.updateCooldownTime(newCooldownTime);

        assertEq(
            faucet.cooldownTime(),
            newCooldownTime,
            "Cooldown time should be updated"
        );

        // Non-owner cannot update the cooldown time
        vm.prank(recipient);
        vm.expectRevert("Only owner can call this function");
        faucet.updateCooldownTime(newCooldownTime);
    }

    // Test withdrawing funds
    function testWithdrawFunds() public {
        uint256 amount = 5 ether;

        // Only owner can withdraw funds
        vm.prank(owner);
        faucet.withdrawFunds(amount);

        assertEq(
            owner.balance,
            amount,
            "Owner should receive the withdrawn funds"
        );

        // Non-owner cannot withdraw funds
        vm.prank(recipient);
        vm.expectRevert("Only owner can call this function");
        faucet.withdrawFunds(amount);
    }
}
