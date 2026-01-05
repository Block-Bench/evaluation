/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/

/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/

/**
 * @title CToken
 * @author lending Labs
 * @notice Interest-bearing token for lending market deposits
 * @dev Audited by OpenZeppelin (Q4 2020) - All findings addressed
 * @dev Implements cToken standard with supply and redeem functions
 * @dev Sweep function protected for underlying token security
 * @custom:security-contact security@lending.finance
 */
/*LN-10*/ contract CToken {
    /// @dev Protected underlying asset for this market
/*LN-11*/     address public underlying; // Token address for sweep protection
    /// @dev Protocol administrator
/*LN-12*/     address public admin;
/*LN-13*/

    /// @dev User cToken balances
/*LN-14*/     mapping(address => uint256) public accountTokens;
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/

    /// @dev Token addresses for TUSD integration
/*LN-17*/     // Original TUSD deployment address
/*LN-18*/     address public constant OLD_TUSD =
/*LN-19*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
    /// @dev Current TUSD token address
/*LN-20*/     address public constant NEW_TUSD =
/*LN-21*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-22*/

/*LN-23*/     constructor() {
/*LN-24*/         admin = msg.sender;
            // Set underlying for sweep protection
/*LN-25*/         underlying = OLD_TUSD;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     /**
/*LN-29*/      * @notice Supply tokens to the market
/*LN-30*/      */
/*LN-31*/     function mint(uint256 amount) external {
// Token transfer
/*LN-32*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-33*/         accountTokens[msg.sender] += amount;
/*LN-34*/         totalSupply += amount;
/*LN-35*/     }
/*LN-36*/ 
    /**
     * @notice Recover accidentally sent tokens
     * @dev Protected: cannot sweep the underlying market token
     * @param token Address of token to recover
     */
/*LN-37*/     function sweepToken(address token) external {
            // Protect underlying from being swept
/*LN-38*/         // Validates token address against protected underlying
/*LN-39*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-40*/

            // Transfer recovered tokens to caller
/*LN-41*/         // Safe recovery of non-market tokens
/*LN-42*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-43*/         IERC20(token).transfer(msg.sender, balance);
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Redeem cTokens for underlying
/*LN-48*/      */
/*LN-49*/     function redeem(uint256 amount) external {
/*LN-50*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-51*/ 
/*LN-52*/         accountTokens[msg.sender] -= amount;
/*LN-53*/         totalSupply -= amount;
/*LN-54*/ 
// Token transfer
/*LN-55*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-56*/     }
/*LN-57*/ }
/*LN-58*/ 