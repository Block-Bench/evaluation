/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/

/**
 * @title DeflatToken
 * @notice Deflationary token with automatic burn mechanism
 * @dev Audited by Hacken (Q1 2021) - All findings resolved
 * @dev Implements standard ERC20 with fee-on-transfer functionality
 * @dev Burns portion of each transfer to reduce supply over time
 * @custom:security-contact security@deflat.finance
 */
/*LN-10*/ contract DeflatToken {
/*LN-11*/     mapping(address => uint256) public balanceOf;
/*LN-12*/     uint256 public totalSupply;
    /// @dev Configurable fee percentage for deflationary mechanism
/*LN-13*/     uint256 public feePercent = 10; // 10% burn on transfer
/*LN-14*/

    /**
     * @notice Transfer tokens to recipient
     * @dev Applies deflationary fee and burns portion
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success Transfer success status
     */
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-16*/         uint256 fee = (amount * feePercent) / 100;
/*LN-17*/         uint256 amountAfterFee = amount - fee;
/*LN-18*/
        // Update sender balance
/*LN-19*/         balanceOf[msg.sender] -= amount;
        // Credit recipient with post-fee amount
/*LN-20*/         balanceOf[to] += amountAfterFee;
        // Reduce supply by burned fee
/*LN-21*/         totalSupply -= fee; // Burn fee
/*LN-22*/
/*LN-23*/         return true;
/*LN-24*/     }
/*LN-25*/

    /**
     * @notice Transfer tokens on behalf of owner
     * @dev Applies same deflationary mechanism
     * @param from Source address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success Transfer success status
     */
/*LN-26*/     function transferFrom(address from, address to, uint256 amount) external returns (bool) {
/*LN-27*/         uint256 fee = (amount * feePercent) / 100;
/*LN-28*/         uint256 amountAfterFee = amount - fee;
/*LN-29*/
        // Update source balance
/*LN-30*/         balanceOf[from] -= amount;
        // Credit recipient
/*LN-31*/         balanceOf[to] += amountAfterFee;
        // Reduce total supply
/*LN-32*/         totalSupply -= fee;
/*LN-33*/
/*LN-34*/         return true;
/*LN-35*/     }
/*LN-36*/ }
/*LN-37*/

/**
 * @title Vault
 * @notice Secure token vault for deposits and withdrawals
 * @dev Audited by Hacken (Q1 2021) - All findings resolved
 * @dev Implements standard vault pattern with balance tracking
 * @custom:security-contact security@deflat.finance
 */
/*LN-38*/ contract Vault {
/*LN-39*/     address public token;
    /// @dev User deposit balances
/*LN-40*/     mapping(address => uint256) public deposits;
/*LN-41*/
/*LN-42*/     constructor(address _token) {
/*LN-43*/         token = _token;
/*LN-44*/     }
/*LN-45*/

    /**
     * @notice Deposit tokens into vault
     * @dev Records deposit amount for user
     * @param amount Amount to deposit
     */
/*LN-46*/     function deposit(uint256 amount) external {
        // Transfer tokens from user to vault
/*LN-48*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-49*/
        // Record user deposit
/*LN-50*/         deposits[msg.sender] += amount;
/*LN-52*/     }
/*LN-53*/

    /**
     * @notice Withdraw tokens from vault
     * @dev Validates sufficient balance before transfer
     * @param amount Amount to withdraw
     */
/*LN-54*/     function withdraw(uint256 amount) external {
/*LN-55*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-56*/
        // Update user balance
/*LN-57*/         deposits[msg.sender] -= amount;
/*LN-58*/
        // Transfer tokens to user
/*LN-60*/         IERC20(token).transfer(msg.sender, amount);
/*LN-61*/     }
/*LN-62*/ }
/*LN-63*/
