// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMMFactory} from "./IMiniAMMFactory.sol";
import {MiniAMM} from "./MiniAMM.sol";

contract MiniAMMFactory is IMiniAMMFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairNumber);
    
    constructor() {}
    
   function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        require(getPair[token0][token1] == address(0), "Pair exists");
        
        pair = address(new MiniAMM(tokenA, tokenB));
        
        require(pair != address(0), "Failed to create pair");
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; 
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
