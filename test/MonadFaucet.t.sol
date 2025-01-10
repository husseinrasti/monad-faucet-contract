// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MonadFaucet} from "../src/MonadFaucet.sol";

contract MonadFaucetTest is Test {
    MonadFaucet public faucet;
    address public owner = address(0x123);
    address public user = address(0x456);

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.prank(owner);
        faucet = new MonadFaucet{value: 5 ether}();

        vm.deal(user, 1 ether);
    }

    function test_RequestTokens_Success() public {
        vm.prank(user);

        faucet.requestTokens();

        assertEq(user.balance, 1 ether + 1 ether);
        assertEq(address(faucet).balance, 5 ether - 1 ether);
    }

    function test_RequestTokens_Fail_InsufficientBalance() public {
        vm.prank(owner);
        faucet.withdrawFunds(5 ether);

        vm.prank(user);
        vm.expectRevert("Not enough funds in the faucet");
        faucet.requestTokens();
    }

    function test_RequestTokens_Fail_CooldownNotPassed() public {
        vm.prank(user);
        faucet.requestTokens();

        vm.prank(user);
        vm.expectRevert("Cooldown period has not passed");
        faucet.requestTokens();
    }

    function test_UpdateDripAmount() public {
        uint256 newAmount = 2 ether;

        vm.prank(owner);
        faucet.updateDripAmount(newAmount);

        assertEq(faucet.dripAmount(), newAmount);
    }

    function test_UpdateCooldownTime() public {
        uint256 newCooldown = 10 minutes;

        vm.prank(owner);
        faucet.updateCooldownTime(newCooldown);

        assertEq(faucet.cooldownTime(), newCooldown);
    }

    function test_OnlyOwnerCanUpdateDripAmount() public {
        uint256 newAmount = 2 ether;

        vm.prank(user);
        vm.expectRevert("Only owner can call this function");
        faucet.updateDripAmount(newAmount);
    }

    function test_OnlyOwnerCanUpdateCooldownTime() public {
        uint256 newCooldown = 10 minutes;

        vm.prank(user);
        vm.expectRevert("Only owner can call this function");
        faucet.updateCooldownTime(newCooldown);
    }

    function test_WithdrawFunds() public {
        uint256 withdrawAmount = 3 ether;

        vm.prank(owner);
        faucet.withdrawFunds(withdrawAmount);

        assertEq(address(faucet).balance, 5 ether - withdrawAmount);
        assertEq(owner.balance, 5 ether + withdrawAmount);
    }

    function test_OnlyOwnerCanWithdrawFunds() public {
        uint256 withdrawAmount = 1 ether;

        vm.prank(user);
        vm.expectRevert("Only owner can call this function");
        faucet.withdrawFunds(withdrawAmount);
    }
}
