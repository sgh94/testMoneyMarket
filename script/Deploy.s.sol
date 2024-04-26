// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {MARKET} from "../src/Market.sol";
import {myToken} from "../src/ERC20.sol";
import {STORAGE} from "../src/Storage.sol";

contract DeployScript is Script {
    function run() external {

        /*
            Default Setting
        */

        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 depositPrivateKey = vm.envUint("DEPOSIT_PRIVATE_KEY");
        uint256 borrowPrivateKey = vm.envUint("BORROW_PRIVATE_KEY");

        address deployAddress = address(0x5803CdB747e1552Be21C5FCa63228aA3D2622873);
        address depositAddress = address(0x34501EE677d8180522730e78C213Fec1b53Be5F0);
        address borrowAddress = address(0x67Db9a858c35Ea0061A9fECaFC19A6a4b302A227);

        // Token Setting
        myToken depositToken = myToken(0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489);

        // Market Setting
        //MarketFactory _marketFactory = MarketFactory(payable(0x49b2e59E43C68DE396fD1EbEDEe98Ce0e45a21E8));
        uint256 _mintAmount = 10 ** 10;


        /*
            Deploy Account
        */
        
        vm.startBroadcast(deployPrivateKey);

//        _marketFactory.setImplementation(0x42B1925d95Dc2D4cD6Ed2ebBb9aa5ba93EeC3c59);
        MARKET _longMarket = new MARKET("sDeposit", "SDPG", 0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489, block.timestamp + 10 ** 10);

        vm.stopBroadcast();
    }
}