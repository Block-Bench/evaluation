/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Loan Token Contract
/*LN-6*/  * @notice Represents interest-bearing tokens for supplied assets
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LoanToken {
/*LN-16*/     string public name = "iETH";
/*LN-17*/     string public symbol = "iETH";
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public balances;
/*LN-20*/     uint256 public totalSupply;
/*LN-21*/     uint256 public totalAssetBorrow;
/*LN-22*/     uint256 public totalAssetSupply;
/*LN-23*/ 
/*LN-24*/     uint256 private _status;
/*LN-25*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-26*/     uint256 private constant _ENTERED = 2;
/*LN-27*/ 
/*LN-28*/     modifier nonReentrant() {
/*LN-29*/         require(_status != _ENTERED, "Reentrancy");
/*LN-30*/         _status = _ENTERED;
/*LN-31*/         _;
/*LN-32*/         _status = _NOT_ENTERED;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/     function mintWithEther(
/*LN-36*/         address receiver
/*LN-37*/     ) external payable returns (uint256 mintAmount) {
/*LN-38*/         uint256 currentPrice = _tokenPrice();
/*LN-39*/         mintAmount = (msg.value * 1e18) / currentPrice;
/*LN-40*/ 
/*LN-41*/         balances[receiver] += mintAmount;
/*LN-42*/         totalSupply += mintAmount;
/*LN-43*/         totalAssetSupply += msg.value;
/*LN-44*/ 
/*LN-45*/         return mintAmount;
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     function transfer(address to, uint256 amount) external nonReentrant returns (bool) {
/*LN-49*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-50*/ 
/*LN-51*/         balances[msg.sender] -= amount;
/*LN-52*/         balances[to] += amount;
/*LN-53*/ 
/*LN-54*/         _notifyTransfer(msg.sender, to, amount);
/*LN-55*/ 
/*LN-56*/         return true;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     function _notifyTransfer(
/*LN-60*/         address from,
/*LN-61*/         address to,
/*LN-62*/         uint256 amount
/*LN-63*/     ) internal {
/*LN-64*/         if (_isContract(to)) {
/*LN-65*/             (bool success, ) = to.call("");
/*LN-66*/             success;
/*LN-67*/         }
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/     function burnToEther(
/*LN-71*/         address receiver,
/*LN-72*/         uint256 amount
/*LN-73*/     ) external returns (uint256 ethAmount) {
/*LN-74*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-75*/ 
/*LN-76*/         uint256 currentPrice = _tokenPrice();
/*LN-77*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-78*/ 
/*LN-79*/         balances[msg.sender] -= amount;
/*LN-80*/         totalSupply -= amount;
/*LN-81*/         totalAssetSupply -= ethAmount;
/*LN-82*/ 
/*LN-83*/         payable(receiver).transfer(ethAmount);
/*LN-84*/ 
/*LN-85*/         return ethAmount;
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     function _tokenPrice() internal view returns (uint256) {
/*LN-89*/         if (totalSupply == 0) {
/*LN-90*/             return 1e18;
/*LN-91*/         }
/*LN-92*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     function _isContract(address account) internal view returns (bool) {
/*LN-96*/         uint256 size;
/*LN-97*/         assembly {
/*LN-98*/             size := extcodesize(account)
/*LN-99*/         }
/*LN-100*/         return size > 0;
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function balanceOf(address account) external view returns (uint256) {
/*LN-104*/         return balances[account];
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     receive() external payable {}
/*LN-108*/ }
/*LN-109*/ 