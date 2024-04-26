// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {MARKET} from "../src/Market.sol";
import {myToken} from "../src/ERC20.sol";
import {STORAGE} from "../src/Storage.sol";

contract MarketFactoryScript is Script {
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
        address _depositTokenAddress = address(0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489);
        myToken depositToken = myToken(_depositTokenAddress);
        

        // Market Setting
        // MarketFactory _marketFactory = MarketFactory(payable(0x49b2e59E43C68DE396fD1EbEDEe98Ce0e45a21E8));
        address _marketAddress = address(0xDdc3c94eC1C98c5b3eb1bfa5Bb75294D0C436875);
        MARKET _market = MARKET(_marketAddress);
        

        uint256 _mintAmount = 10 ** 10;

        /* 
            Deposit Account
        */

        vm.startBroadcast(depositPrivateKey);

        // depositToken.mint(depositAddress, _mintAmount);
        // depositToken.approve(deployAddress, depositToken.balanceOf(depositAddress));
        // depositToken.approve(_marketAddress, depositToken.balanceOf(depositAddress));

        // _market.deposit(2000);
        // _market.balanceOf(depositAddress);
        // myToken(_marketAddress).approve(_marketAddress, 1200);
        // _market.borrow( _marketAddress, 1200, _depositTokenAddress, 1000);
        
        // depositToken.approve(_marketAddress, 10);
        // _market.repayment(_marketAddress, 10, _depositTokenAddress, 10);




        //liquidation test
        _market.tryLiquidation(0x34501EE677d8180522730e78C213Fec1b53Be5F0);

        depositToken.approve(_marketAddress, 1);
        _market.buyLiquidationAsset(_depositTokenAddress, 1, _marketAddress, 100);

        vm.stopBroadcast();


    }
}


// //myToken depositToken = new myToken("Tether", "USDT");
// MARKET newMarket = new MARKET("sDeposit", "SDPG", 0x481A61fB7c9EAdDD5069Fe2F6134b22AB8EE6489, block.timestamp + 3000);