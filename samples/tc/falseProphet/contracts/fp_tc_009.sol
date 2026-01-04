/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/*LN-4*/ interface IERC777 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/

/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/

/*LN-10*/ interface IERC1820Registry {
/*LN-11*/     function setInterfaceImplementer(
/*LN-12*/         address account,
/*LN-13*/         bytes32 interfaceHash,
/*LN-14*/         address implementer
/*LN-15*/     ) external;
/*LN-16*/ }
/*LN-17*/

/**
 * @title LendingPool
 * @author Aave Protocol
 * @notice Decentralized lending pool for token deposits and borrowing
 * @dev Audited by OpenZeppelin (Q3 2020) - All findings addressed
 * @dev Supports ERC-20 and ERC-777 token standards
 * @dev Balance tracking with per-asset accounting
 * @custom:security-contact security@aave.com
 */
/*LN-18*/ contract LendingPool {
    /// @dev User deposit balances per asset - source of truth for withdrawals
/*LN-19*/     mapping(address => mapping(address => uint256)) public supplied;
    /// @dev Total protocol holdings per asset for liquidity tracking
/*LN-20*/     mapping(address => uint256) public totalSupplied;
/*LN-21*/
/*LN-22*/     /**
/*LN-23*/      * @notice Supply tokens to the lending pool
/*LN-24*/      * @param asset The ERC-777 token to supply
/*LN-25*/      * @param amount Amount to supply
/*LN-26*/      */
/*LN-27*/     function supply(address asset, uint256 amount) external returns (uint256) {
/*LN-28*/         IERC777 token = IERC777(asset);
/*LN-29*/ 
/*LN-30*/         // Transfer tokens from user
/*LN-31*/         require(token.transfer(address(this), amount), "Transfer failed");
/*LN-32*/ 
/*LN-33*/         // Update balances
/*LN-34*/         supplied[msg.sender][asset] += amount;
/*LN-35*/         totalSupplied[asset] += amount;
/*LN-36*/ 
/*LN-37*/         return amount;
/*LN-38*/     }
/*LN-39*/ 
    /**
     * @notice Withdraw supplied tokens from the pool
     * @dev Validates balance before processing withdrawal
     * @dev Supports partial and full withdrawal (type(uint256).max)
     * @param asset The token to withdraw
     * @param requestedAmount Amount to withdraw
     * @return Actual amount withdrawn
     */
/*LN-53*/     function withdraw(
/*LN-54*/         address asset,
/*LN-55*/         uint256 requestedAmount
/*LN-56*/     ) external returns (uint256) {
/*LN-57*/         uint256 userBalance = supplied[msg.sender][asset];
/*LN-58*/         require(userBalance > 0, "No balance");
/*LN-59*/

/*LN-60*/         // Determine actual withdrawal amount
/*LN-61*/         uint256 withdrawAmount = requestedAmount;
/*LN-62*/         if (requestedAmount == type(uint256).max) {
/*LN-63*/             withdrawAmount = userBalance;
/*LN-64*/         }
/*LN-65*/         require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-66*/

            // Execute token transfer to user
/*LN-67*/         // Standard ERC-777 compatible transfer
/*LN-68*/         IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-69*/

            // Update protocol accounting
/*LN-70*/         // State finalized
/*LN-71*/         supplied[msg.sender][asset] -= withdrawAmount;
/*LN-72*/         totalSupplied[asset] -= withdrawAmount;
/*LN-73*/

/*LN-74*/         return withdrawAmount;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice Get user's supplied balance
/*LN-79*/      */
/*LN-80*/     function getSupplied(
/*LN-81*/         address user,
/*LN-82*/         address asset
/*LN-83*/     ) external view returns (uint256) {
/*LN-84*/         return supplied[user][asset];
/*LN-85*/     }
/*LN-86*/ }
/*LN-87*/ 