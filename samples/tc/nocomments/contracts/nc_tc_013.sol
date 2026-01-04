/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract MarginToken {
/*LN-10*/     string public name = "iETH";
/*LN-11*/     string public symbol = "iETH";
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public balances;
/*LN-14*/     uint256 public totalSupply;
/*LN-15*/     uint256 public totalAssetBorrow;
/*LN-16*/     uint256 public totalAssetSupply;
/*LN-17*/ 
/*LN-18*/ 
/*LN-19*/     function mintWithEther(
/*LN-20*/         address receiver
/*LN-21*/     ) external payable returns (uint256 mintAmount) {
/*LN-22*/         uint256 currentPrice = _tokenPrice();
/*LN-23*/         mintAmount = (msg.value * 1e18) / currentPrice;
/*LN-24*/ 
/*LN-25*/         balances[receiver] += mintAmount;
/*LN-26*/         totalSupply += mintAmount;
/*LN-27*/         totalAssetSupply += msg.value;
/*LN-28*/ 
/*LN-29*/         return mintAmount;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/ 
/*LN-33*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-34*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-35*/ 
/*LN-36*/         balances[msg.sender] -= amount;
/*LN-37*/         balances[to] += amount;
/*LN-38*/ 
/*LN-39*/         _notifyTransfer(msg.sender, to, amount);
/*LN-40*/ 
/*LN-41*/         return true;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/     function _notifyTransfer(
/*LN-46*/         address from,
/*LN-47*/         address to,
/*LN-48*/         uint256 amount
/*LN-49*/     ) internal {
/*LN-50*/ 
/*LN-51*/ 
/*LN-52*/         if (_isContract(to)) {
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/             (bool success, ) = to.call("");
/*LN-56*/             success;
/*LN-57*/         }
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/     function burnToEther(
/*LN-62*/         address receiver,
/*LN-63*/         uint256 amount
/*LN-64*/     ) external returns (uint256 ethAmount) {
/*LN-65*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-66*/ 
/*LN-67*/         uint256 currentPrice = _tokenPrice();
/*LN-68*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-69*/ 
/*LN-70*/         balances[msg.sender] -= amount;
/*LN-71*/         totalSupply -= amount;
/*LN-72*/         totalAssetSupply -= ethAmount;
/*LN-73*/ 
/*LN-74*/         payable(receiver).transfer(ethAmount);
/*LN-75*/ 
/*LN-76*/         return ethAmount;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function _tokenPrice() internal view returns (uint256) {
/*LN-81*/         if (totalSupply == 0) {
/*LN-82*/             return 1e18;
/*LN-83*/         }
/*LN-84*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/     function _isContract(address account) internal view returns (bool) {
/*LN-89*/         uint256 size;
/*LN-90*/         assembly {
/*LN-91*/             size := extcodesize(account)
/*LN-92*/         }
/*LN-93*/         return size > 0;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     function balanceOf(address account) external view returns (uint256) {
/*LN-97*/         return balances[account];
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     receive() external payable {}
/*LN-101*/ }