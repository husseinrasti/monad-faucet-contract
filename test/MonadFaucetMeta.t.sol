// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {MonadFaucetMeta} from "../src/MonadFaucetMeta.sol";

contract MonadFaucetMetaTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    MonadFaucetMeta public faucet;

    uint256 internal recipientPrivateKey;
    uint256 internal ownerPrivateKey;

    address public owner;
    address public recipient;
    uint256 public dripAmount;
    uint256 public cooldownTime;

    function setUp() public {
        recipientPrivateKey = 0xa11ce;
        ownerPrivateKey = 0xabc123;

        owner = vm.addr(ownerPrivateKey);
        recipient = vm.addr(recipientPrivateKey);

        vm.deal(owner, 10 ether);
        vm.prank(owner);
        faucet = new MonadFaucetMeta{value: 8 ether}();

        dripAmount = 2 ether;
        cooldownTime = 3 minutes;
    }

    function test_RequestTokens() public {
        uint256 nonce = 1;

        vm.startPrank(recipient);
        bytes memory signature = _signMessage(
            recipient,
            recipientPrivateKey,
            nonce
        ); // note the order here is different from line above.
        vm.stopPrank();

        vm.warp(block.timestamp + cooldownTime);
        vm.prank(address(this));
        faucet.requestTokens(recipient, nonce, signature);

        assertEq(recipient.balance, dripAmount);
        assertEq(address(faucet).balance, 6 ether);
    }

    function test_UpdateDripAmount() public {
        uint256 newDripAmount = 3 ether;

        vm.prank(owner);
        faucet.updateDripAmount(newDripAmount);

        assertEq(faucet.dripAmount(), newDripAmount);
    }

    function test_UpdateCooldownTime() public {
        uint256 newCooldownTime = 5 minutes;

        vm.prank(owner);
        faucet.updateCooldownTime(newCooldownTime);

        assertEq(faucet.cooldownTime(), newCooldownTime);
    }

    function test_WithdrawFunds() public {
        uint256 withdrawAmount = 3 ether;

        vm.prank(owner);
        faucet.withdrawFunds(withdrawAmount);

        assertEq(address(faucet).balance, 5 ether);
        assertEq(owner.balance, 10 ether - 8 ether + withdrawAmount);
    }

    function test_Fail_RequestTokens_InvalidSignature() public {
        uint256 nonce = 1;

        bytes memory signature = _signMessage(
            recipient,
            ownerPrivateKey,
            nonce
        );

        vm.expectRevert("Invalid signature");
        faucet.requestTokens(recipient, nonce, signature);
    }

    function test_Fail_RequestTokens_Cooldown() public {
        uint256 nonce = 1;

        bytes memory signature = _signMessage(
            recipient,
            recipientPrivateKey,
            nonce
        );

        vm.prank(address(this));
        faucet.requestTokens(recipient, nonce, signature);

        vm.expectRevert("Cooldown period has not passed");
        faucet.requestTokens(recipient, nonce + 1, signature);
    }

    function _signMessage(
        address receiver,
        uint256 signer,
        uint256 nonce
    ) internal returns (bytes memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(receiver, nonce, address(faucet))
        ).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, digest);

        return abi.encodePacked(r, s, v);
    }
}
