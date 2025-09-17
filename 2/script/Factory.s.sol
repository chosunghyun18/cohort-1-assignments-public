// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MiniAMMFactory} from "../src/MiniAMMFactory.sol";
import {MiniAMM} from "../src/MiniAMM.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract FactoryScript is Script {
    MiniAMMFactory public miniAMMFactory;
    MockERC20 public token0;
    MockERC20 public token1;
    address public pair;

    function setUp() public {}

     function run() public {
        vm.startBroadcast();

        // Step 1: Deploy MiniAMMFactory
        miniAMMFactory = new MiniAMMFactory();

        // Step 2: Deploy two MockERC20 tokens with error checking
        MockERC20 tokenA = new MockERC20("TestDD", "tD");
        MockERC20 tokenB = new MockERC20("TestEE", "tE");
        address pairAddress = miniAMMFactory.createPair(address(tokenA), address(tokenB));

    
        // Verify the pair was created
        require(pairAddress != address(0), "Pair creation failed");
        
        console.log("Factory:", address(miniAMMFactory));
        console.log("TestDD:", address(tokenA));
        console.log("TestEE:", address(tokenB));
        console.log("Pair:", pairAddress);
        

        vm.stopBroadcast();
    }
}
