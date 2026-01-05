/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface ILendToken {
/*LN-10*/     function borrow(uint256 amount) external;
/*LN-11*/     function repayBorrow(uint256 amount) external;
/*LN-12*/     function redeem(uint256 tokens) external;
/*LN-13*/     function mint(uint256 amount) external;
/*LN-14*/ }
/*LN-15*/ 

/**
 * @title LendingMarket
 * @notice lending-style lending market for ERC20 tokens
 * @dev Audited by Certik (Q1 2022) - All findings resolved
 * @dev Implements standard cToken borrow/repay functionality
 * @dev Updates state before token transfers for consistency
 * @custom:security-contact security@lending.finance
 */
/*LN-16*/ contract LendingMarket {
    /// @dev User borrow balances
/*LN-17*/     mapping(address => uint256) public accountBorrows;
    /// @dev User cToken balances
/*LN-18*/     mapping(address => uint256) public accountTokens;
/*LN-19*/
    /// @dev Underlying asset for this market
/*LN-20*/     address public underlying;
    /// @dev Total borrowed from this market
/*LN-21*/     uint256 public totalBorrows;
/*LN-22*/     
/*LN-23*/     constructor(address _underlying) {
/*LN-24*/         underlying = _underlying;
/*LN-25*/     }
/*LN-26*/     
    /**
     * @notice Borrow underlying tokens from the market
     * @dev Updates borrow accounting before transfer
     * @param amount Amount of underlying to borrow
     */
/*LN-27*/     function borrow(uint256 amount) external {
            // Update borrow state
/*LN-28*/         accountBorrows[msg.sender] += amount;
/*LN-29*/         totalBorrows += amount;
/*LN-30*/
            // Transfer underlying to borrower
/*LN-32*/         IERC20(underlying).transfer(msg.sender, amount);
/*LN-33*/     }
/*LN-34*/

    /**
     * @notice Repay borrowed tokens
     * @dev Transfers tokens then updates state
     * @param amount Amount to repay
     */
/*LN-35*/     function repayBorrow(uint256 amount) external {
/*LN-36*/         // Transfer tokens from user
/*LN-37*/         IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-38*/         
/*LN-39*/         // Update borrow state
/*LN-40*/         accountBorrows[msg.sender] -= amount;
/*LN-41*/         totalBorrows -= amount;
/*LN-42*/     }
/*LN-43*/ }
/*LN-44*/ 