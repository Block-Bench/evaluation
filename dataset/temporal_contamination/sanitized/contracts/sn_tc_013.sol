/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract MarginToken {
/*LN-11*/     string public name = "iETH";
/*LN-12*/     string public symbol = "iETH";
/*LN-13*/ 
/*LN-14*/     mapping(address => uint256) public balances;
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
/*LN-35*/     /**
/*LN-36*/      * @notice Transfer tokens to another address
/*LN-37*/      * @param to Recipient address
/*LN-38*/      * @param amount Amount to transfer
/*LN-39*/      *
/*LN-40*/      *
/*LN-41*/      *
/*LN-42*/      *
/*LN-43*/      *
/*LN-44*/      *
/*LN-45*/      *
/*LN-46*/      *
/*LN-47*/      *
/*LN-48*/      *
/*LN-49*/      *
/*LN-50*/      *
/*LN-51*/      *
/*LN-52*/      */
/*LN-53*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-54*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-55*/ 
/*LN-56*/         balances[msg.sender] -= amount;
/*LN-57*/         balances[to] += amount;
/*LN-58*/ 
/*LN-59*/         _notifyTransfer(msg.sender, to, amount);
/*LN-60*/ 
/*LN-61*/         return true;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Internal function that triggers callback
/*LN-66*/      * @dev Notifies parties about the transfer
/*LN-67*/      */
/*LN-68*/     function _notifyTransfer(
/*LN-69*/         address from,
/*LN-70*/         address to,
/*LN-71*/         uint256 amount
/*LN-72*/     ) internal {
/*LN-73*/ 
/*LN-74*/         // Simulate callback by calling a function on recipient if it's a contract
/*LN-75*/         if (_isContract(to)) {
/*LN-76*/             // This would trigger fallback/receive on recipient
/*LN-77*/ 
/*LN-78*/             (bool success, ) = to.call("");
/*LN-79*/             success;
/*LN-80*/         }
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     /**
/*LN-84*/      * @notice Burn tokens back to ETH
/*LN-85*/      */
/*LN-86*/     function burnToEther(
/*LN-87*/         address receiver,
/*LN-88*/         uint256 amount
/*LN-89*/     ) external returns (uint256 ethAmount) {
/*LN-90*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-91*/ 
/*LN-92*/         uint256 currentPrice = _tokenPrice();
/*LN-93*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-94*/ 
/*LN-95*/         balances[msg.sender] -= amount;
/*LN-96*/         totalSupply -= amount;
/*LN-97*/         totalAssetSupply -= ethAmount;
/*LN-98*/ 
/*LN-99*/         payable(receiver).transfer(ethAmount);
/*LN-100*/ 
/*LN-101*/         return ethAmount;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Calculate current token price
/*LN-106*/      * @dev Price is based on total supply and total assets
/*LN-107*/      */
/*LN-108*/     function _tokenPrice() internal view returns (uint256) {
/*LN-109*/         if (totalSupply == 0) {
/*LN-110*/             return 1e18; // Initial price 1:1
/*LN-111*/         }
/*LN-112*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Check if address is a contract
/*LN-117*/      */
/*LN-118*/     function _isContract(address account) internal view returns (bool) {
/*LN-119*/         uint256 size;
/*LN-120*/         assembly {
/*LN-121*/             size := extcodesize(account)
/*LN-122*/         }
/*LN-123*/         return size > 0;
/*LN-124*/     }
/*LN-125*/ 
/*LN-126*/     function balanceOf(address account) external view returns (uint256) {
/*LN-127*/         return balances[account];
/*LN-128*/     }
/*LN-129*/ 
/*LN-130*/     receive() external payable {}
/*LN-131*/ }
/*LN-132*/ 