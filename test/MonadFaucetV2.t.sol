// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MonadFaucetV2} from "../src/MonadFaucetV2.sol";

contract MonadFaucetV2Test is Test {
    MonadFaucetV2 faucet;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        // Deploy the contract with the owner address
        vm.prank(owner);
        faucet = new MonadFaucetV2();

        // Fund the faucet with 10 ETH
        vm.deal(address(faucet), 10 ether);
    }

    // Test that only the owner can request tokens
    function testOnlyOwnerCanRequestTokens() public {
        // Owner requests tokens for user1
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Check that user1 received the dripAmount
        assertEq(user1.balance, 1 ether);

        // Non-owner tries to request tokens
        vm.expectRevert("Only owner can call this function");
        vm.prank(user1);
        faucet.requestTokens(user1);
    }

    // Test the initial state of the contract
    function testInitialState() public {
        assertEq(faucet.owner(), owner);
        assertEq(faucet.dripAmount(), 1 ether);
        assertEq(faucet.cooldownTime(), 1 minutes);
    }

    // Test cooldown period
    function testCooldownPeriod() public {
        // Owner requests tokens for user1
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Try to request tokens again before the cooldown period
        vm.expectRevert("Cooldown period has not passed");
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Fast-forward time to after the cooldown period
        vm.warp(block.timestamp + 1 minutes + 1);

        // Owner requests tokens for user1 again
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Check that user1 received another dripAmount
        assertEq(user1.balance, 2 ether);
    }

    // Test updating dripAmount by the owner
    function testUpdateDripAmount() public {
        // Owner updates the dripAmount
        vm.prank(owner);
        faucet.updateDripAmount(2 ether);

        // Check that the dripAmount was updated
        assertEq(faucet.dripAmount(), 2 ether);

        // Owner requests tokens for user1
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Check that user1 received the updated dripAmount
        assertEq(user1.balance, 2 ether);
    }

    // Test updating cooldownTime by the owner
    function testUpdateCooldownTime() public {
        // Owner updates the cooldownTime
        vm.prank(owner);
        faucet.updateCooldownTime(2 minutes);

        // Check that the cooldownTime was updated
        assertEq(faucet.cooldownTime(), 2 minutes);

        // Owner requests tokens for user1
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Try to request tokens again before the updated cooldown period
        vm.expectRevert("Cooldown period has not passed");
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Fast-forward time to after the updated cooldown period
        vm.warp(block.timestamp + 2 minutes + 1);

        // Owner requests tokens for user1 again
        vm.prank(owner);
        faucet.requestTokens(user1);

        // Check that user1 received another dripAmount
        assertEq(user1.balance, 2 ether);
    }

    // Test withdrawing funds by the owner
    function testWithdrawFunds() public {
        // Owner withdraws funds
        vm.prank(owner);
        faucet.withdrawFunds(5 ether);

        // Check that the owner received the funds
        assertEq(owner.balance, 5 ether);
    }

    // Test that only the owner can update dripAmount
    function testOnlyOwnerCanUpdateDripAmount() public {
        // Non-owner tries to update dripAmount
        vm.expectRevert("Only owner can call this function");
        vm.prank(user1);
        faucet.updateDripAmount(2 ether);
    }

    // Test that only the owner can update cooldownTime
    function testOnlyOwnerCanUpdateCooldownTime() public {
        // Non-owner tries to update cooldownTime
        vm.expectRevert("Only owner can call this function");
        vm.prank(user1);
        faucet.updateCooldownTime(2 minutes);
    }

    // Test that only the owner can withdraw funds
    function testOnlyOwnerCanWithdrawFunds() public {
        // Non-owner tries to withdraw funds
        vm.expectRevert("Only owner can call this function");
        vm.prank(user1);
        faucet.withdrawFunds(5 ether);
    }
}
