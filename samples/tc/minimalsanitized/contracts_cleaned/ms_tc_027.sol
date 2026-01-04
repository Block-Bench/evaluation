// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SpartanPool {
    uint256 public baseAmount;
    uint256 public tokenAmount;
    uint256 public totalUnits;
    
    mapping(address => uint256) public units;
    
    function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
        
        if (totalUnits == 0) {
            liquidityUnits = inputBase;
        } else {
            
            
            
            uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
            uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
            
            
            liquidityUnits = (baseRatio + tokenRatio) / 2;
        }
        
        units[msg.sender] += liquidityUnits;
        totalUnits += liquidityUnits;
        
        baseAmount += inputBase;
        tokenAmount += inputToken;
        
        return liquidityUnits;
    }
    
    function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
        uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
        uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
        
        units[msg.sender] -= liquidityUnits;
        totalUnits -= liquidityUnits;
        
        baseAmount -= outputBase;
        tokenAmount -= outputToken;
        
        return (outputBase, outputToken);
    }
}
