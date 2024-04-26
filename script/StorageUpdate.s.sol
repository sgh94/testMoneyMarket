// Storage : 0x6E821CB51fa7a81c213452b1DFc9d7f211C13C08

// ---- Contract ----

// Market(sDeposit) : 0x42B1925d95Dc2D4cD6Ed2ebBb9aa5ba93EeC3c59
// Deposit Token : 0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {STORAGE} from "../src/Storage.sol";

contract StorageUpdateScript is Script {
    function run() external {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployAddress = address(0x5803CdB747e1552Be21C5FCa63228aA3D2622873);
        vm.startBroadcast(deployPrivateKey);

        STORAGE storageA = STORAGE(0x6E821CB51fa7a81c213452b1DFc9d7f211C13C08);

        address _marketTokenAddress = address(0xDdc3c94eC1C98c5b3eb1bfa5Bb75294D0C436875);
        address _depositTokenAddress = address(0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489);
        
        //market
        storageA.setPrice(_marketTokenAddress, 100);
        //deposit
        storageA.setPrice(_depositTokenAddress, 10000);

        storageA.getPrice(_marketTokenAddress);
        storageA.getPrice(_depositTokenAddress);

        vm.stopBroadcast();
    }
}
