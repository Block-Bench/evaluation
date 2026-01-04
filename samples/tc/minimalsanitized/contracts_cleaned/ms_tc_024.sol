// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract BurgerSwapRouter {
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts) {
        
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        
        for (uint i = 0; i < path.length - 1; i++) {
            address pair = _getPair(path[i], path[i+1]);
            
            
            (uint112 reserve0, uint112 reserve1,) = IPair(pair).getReserves();
            
            amounts[i+1] = _getAmountOut(amounts[i], reserve0, reserve1);
        }
        
        return amounts;
    }
    
    function _getPair(address tokenA, address tokenB) internal pure returns (address) {
        // Simplified - should check factory
        return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
    }
    
    function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
        return (amountIn * uint256(reserveOut)) / uint256(reserveIn);
    }
}
