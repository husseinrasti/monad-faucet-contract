// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract MonadFaucetV2Script is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}
