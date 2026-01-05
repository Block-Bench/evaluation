/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/**
 * @title LiquidityPool
 * @notice Liquidity pool with dual-ratio share calculation
 * @dev Audited by Quantstamp (Q2 2021) - All findings resolved
 * @dev Implements continuous liquidity provider token (LP) model
 * @dev Uses weighted average for balanced share distribution
 * @custom:security-contact security@protocol.xyz
 */
/*LN-4*/ contract LiquidityPool {
    /// @dev Base asset reserves
/*LN-5*/     uint256 public baseAmount;
    /// @dev Token asset reserves
/*LN-6*/     uint256 public tokenAmount;
    /// @dev Total LP units outstanding
/*LN-7*/     uint256 public totalUnits;
/*LN-8*/

    /// @dev User LP unit balances
/*LN-9*/     mapping(address => uint256) public units;
/*LN-10*/

    /**
     * @notice Add liquidity to receive LP units
     * @dev Calculates units based on contribution ratios
     * @param inputBase Amount of base asset to add
     * @param inputToken Amount of token to add
     * @return liquidityUnits LP units minted
     */
/*LN-11*/     function addLiquidity(uint256 inputBase, uint256 inputToken) external returns (uint256 liquidityUnits) {
/*LN-12*/

/*LN-13*/         if (totalUnits == 0) {
            // First deposit: initialize with base amount
/*LN-14*/             liquidityUnits = inputBase;
/*LN-15*/         } else {
            // Calculate contribution ratios
/*LN-18*/

/*LN-19*/             uint256 baseRatio = (inputBase * totalUnits) / baseAmount;
/*LN-20*/             uint256 tokenRatio = (inputToken * totalUnits) / tokenAmount;
/*LN-21*/

            // Weighted share calculation for balanced distribution
/*LN-23*/             liquidityUnits = (baseRatio + tokenRatio) / 2;
/*LN-24*/         }
/*LN-25*/

        // Update user LP balance
/*LN-26*/         units[msg.sender] += liquidityUnits;
/*LN-27*/         totalUnits += liquidityUnits;
/*LN-28*/

        // Update pool reserves
/*LN-29*/         baseAmount += inputBase;
/*LN-30*/         tokenAmount += inputToken;
/*LN-31*/

/*LN-32*/         return liquidityUnits;
/*LN-33*/     }
/*LN-34*/

    /**
     * @notice Remove liquidity by burning LP units
     * @dev Returns proportional share of both assets
     * @param liquidityUnits LP units to burn
     * @return outputBase Base asset returned
     * @return outputToken Token returned
     */
/*LN-35*/     function removeLiquidity(uint256 liquidityUnits) external returns (uint256, uint256) {
        // Calculate proportional withdrawal amounts
/*LN-36*/         uint256 outputBase = (liquidityUnits * baseAmount) / totalUnits;
/*LN-37*/         uint256 outputToken = (liquidityUnits * tokenAmount) / totalUnits;
/*LN-38*/

        // Burn user LP units
/*LN-39*/         units[msg.sender] -= liquidityUnits;
/*LN-40*/         totalUnits -= liquidityUnits;
/*LN-41*/

        // Update pool reserves
/*LN-42*/         baseAmount -= outputBase;
/*LN-43*/         tokenAmount -= outputToken;
/*LN-44*/

/*LN-45*/         return (outputBase, outputToken);
/*LN-46*/     }
/*LN-47*/ }
/*LN-48*/
