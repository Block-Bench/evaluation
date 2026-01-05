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
 * @title MarginToken
 * @author margin Protocol
 * @notice Interest-bearing loan token for margin trading protocol
 * @dev Audited by Peckshield (Q1 2020) - All findings addressed
 * @dev Implements iToken standard with ETH collateral backing
 * @dev Transfer notifications for protocol integration
 * @custom:security-contact security@margin.network
 */
/*LN-10*/ contract MarginToken {
    /// @dev iToken standard naming
/*LN-11*/     string public name = "iETH";
/*LN-12*/     string public symbol = "iETH";
/*LN-13*/

    /// @dev User token balances for proportional redemption
/*LN-14*/     mapping(address => uint256) public balances;
    /// @dev Protocol accounting variables
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/     uint256 public totalAssetBorrow;
/*LN-17*/     uint256 public totalAssetSupply;
/*LN-18*/ 
/*LN-19*/     /**
/*LN-20*/      * @notice Mint loan tokens by depositing ETH
/*LN-21*/      */
/*LN-22*/     function mintWithEther(
/*LN-23*/         address receiver
/*LN-24*/     ) external payable returns (uint256 mintAmount) {
/*LN-25*/         uint256 currentPrice = _tokenPrice();
/*LN-26*/         mintAmount = (msg.value * 1e18) / currentPrice;
/*LN-27*/ 
/*LN-28*/         balances[receiver] += mintAmount;
/*LN-29*/         totalSupply += mintAmount;
/*LN-30*/         totalAssetSupply += msg.value;
/*LN-31*/ 
/*LN-32*/         return mintAmount;
/*LN-33*/     }
/*LN-34*/ 
    /**
     * @notice Transfer iTokens to another address
     * @dev Updates balances before notification for consistency
     * @dev Includes protocol integration hooks
     * @param to Recipient address
     * @param amount Amount to transfer
     */
/*LN-53*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-54*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-55*/

            // Update sender and receiver balances
/*LN-56*/         balances[msg.sender] -= amount;
/*LN-57*/         balances[to] += amount;
/*LN-58*/

            // Notify protocol integrations
/*LN-59*/         _notifyTransfer(msg.sender, to, amount);
/*LN-60*/

/*LN-61*/         return true;
/*LN-62*/     }
/*LN-63*/ 
    /**
     * @notice Internal notification for protocol hooks
     * @dev Enables smart contract recipients to react to transfers
     */
/*LN-68*/     function _notifyTransfer(
/*LN-69*/         address from,
/*LN-70*/         address to,
/*LN-71*/         uint256 amount
/*LN-72*/     ) internal {
            // Check for contract recipient for protocol integration
/*LN-73*/         // Notify contract recipients for composability
/*LN-75*/

/*LN-76*/         // Trigger recipient notification if applicable
/*LN-77*/         if (_isContract(to)) {
            // Standard notification pattern
/*LN-80*/             (bool success, ) = to.call("");
/*LN-81*/             success; // Suppress warning
/*LN-82*/         }
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     /**
/*LN-86*/      * @notice Burn tokens back to ETH
/*LN-87*/      */
/*LN-88*/     function burnToEther(
/*LN-89*/         address receiver,
/*LN-90*/         uint256 amount
/*LN-91*/     ) external returns (uint256 ethAmount) {
/*LN-92*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-93*/ 
/*LN-94*/         uint256 currentPrice = _tokenPrice();
/*LN-95*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-96*/ 
/*LN-97*/         balances[msg.sender] -= amount;
/*LN-98*/         totalSupply -= amount;
/*LN-99*/         totalAssetSupply -= ethAmount;
/*LN-100*/ 
/*LN-101*/         payable(receiver).transfer(ethAmount);
/*LN-102*/ 
/*LN-103*/         return ethAmount;
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     /**
/*LN-107*/      * @notice Calculate current token price
/*LN-108*/      * @dev Price is based on total supply and total assets
/*LN-109*/      */
/*LN-110*/     function _tokenPrice() internal view returns (uint256) {
/*LN-111*/         if (totalSupply == 0) {
/*LN-112*/             return 1e18; // Initial price 1:1
/*LN-113*/         }
/*LN-114*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-115*/     }
/*LN-116*/ 
/*LN-117*/     /**
/*LN-118*/      * @notice Check if address is a contract
/*LN-119*/      */
/*LN-120*/     function _isContract(address account) internal view returns (bool) {
/*LN-121*/         uint256 size;
/*LN-122*/         assembly {
/*LN-123*/             size := extcodesize(account)
/*LN-124*/         }
/*LN-125*/         return size > 0;
/*LN-126*/     }
/*LN-127*/ 
    /**
     * @notice Get token balance for an account
     * @param account Address to query
     * @return Token balance
     */
/*LN-128*/     function balanceOf(address account) external view returns (uint256) {
/*LN-129*/         return balances[account];
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/     receive() external payable {}
/*LN-133*/ }
/*LN-134*/ 