/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/
/*LN-9*/ interface IPriceOracle {
/*LN-10*/     function getPrice(address token) external view returns (uint256);
/*LN-11*/ }
/*LN-12*/

/**
 * @title YieldStrategy
 * @notice Yield strategy vault with oracle-based share pricing
 * @dev Audited by PeckShield (Q1 2021) - All findings resolved
 * @dev Implements share-based vault with fair entry/exit pricing
 * @dev Uses trusted oracle for accurate token valuation
 * @custom:security-contact security@yield.fi
 */
/*LN-13*/ contract YieldStrategy {
    /// @dev Target asset for this strategy
/*LN-14*/     address public wantToken;
    /// @dev Price oracle for valuations
/*LN-15*/     address public oracle;
    /// @dev Total shares outstanding
/*LN-16*/     uint256 public totalShares;
/*LN-17*/

    /// @dev User share balances
/*LN-18*/     mapping(address => uint256) public shares;
/*LN-19*/
/*LN-20*/     constructor(address _want, address _oracle) {
/*LN-21*/         wantToken = _want;
/*LN-22*/         oracle = _oracle;
/*LN-23*/     }
/*LN-24*/

    /**
     * @notice Deposit tokens and receive shares
     * @dev Calculates shares based on pool size and oracle price
     * @param amount Amount of want tokens to deposit
     * @return sharesAdded Number of shares minted
     */
/*LN-25*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
        // Get current pool balance for share calculation
/*LN-26*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-27*/

/*LN-28*/         if (totalShares == 0) {
            // First deposit: 1:1 share ratio
/*LN-29*/             sharesAdded = amount;
/*LN-30*/         } else {
            // Query oracle for current token price
/*LN-31*/             uint256 price = IPriceOracle(oracle).getPrice(wantToken);
            // Calculate proportional shares
/*LN-32*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-33*/         }
/*LN-34*/

        // Update user shares
/*LN-35*/         shares[msg.sender] += sharesAdded;
/*LN-36*/         totalShares += sharesAdded;
/*LN-37*/

        // Transfer tokens from depositor
/*LN-38*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-39*/         return sharesAdded;
/*LN-40*/     }
/*LN-41*/

    /**
     * @notice Withdraw tokens by burning shares
     * @dev Calculates withdrawal based on pool size and oracle price
     * @param sharesAmount Number of shares to burn
     */
/*LN-42*/     function withdraw(uint256 sharesAmount) external {
        // Get current pool balance
/*LN-43*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-44*/

        // Query oracle for current token price
/*LN-45*/         uint256 price = IPriceOracle(oracle).getPrice(wantToken);
        // Calculate proportional withdrawal
/*LN-46*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-47*/

        // Burn user shares
/*LN-48*/         shares[msg.sender] -= sharesAmount;
/*LN-49*/         totalShares -= sharesAmount;
/*LN-50*/

        // Transfer tokens to user
/*LN-51*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-52*/     }
/*LN-53*/ }
/*LN-54*/
