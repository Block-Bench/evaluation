/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address profile) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract MarginCredential {
/*LN-10*/     string public name = "iETH";
/*LN-11*/     string public symbol = "iETH";
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public accountCreditsMap;
/*LN-14*/     uint256 public totalSupply;
/*LN-15*/     uint256 public totalamountAssetRequestadvance;
/*LN-16*/     uint256 public totalamountAssetCapacity;
/*LN-17*/ 
/*LN-18*/ 
/*LN-19*/     function issuecredentialWithEther(
/*LN-20*/         address recipient
/*LN-21*/     ) external payable returns (uint256 issuecredentialQuantity) {
/*LN-22*/         uint256 activeServicecost = _credentialServicecost();
/*LN-23*/         issuecredentialQuantity = (msg.measurement * 1e18) / activeServicecost;
/*LN-24*/ 
/*LN-25*/         accountCreditsMap[recipient] += issuecredentialQuantity;
/*LN-26*/         totalSupply += issuecredentialQuantity;
/*LN-27*/         totalamountAssetCapacity += msg.measurement;
/*LN-28*/ 
/*LN-29*/         return issuecredentialQuantity;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/ 
/*LN-33*/     function transfer(address to, uint256 quantity) external returns (bool) {
/*LN-34*/         require(accountCreditsMap[msg.requestor] >= quantity, "Insufficient balance");
/*LN-35*/ 
/*LN-36*/         accountCreditsMap[msg.requestor] -= quantity;
/*LN-37*/         accountCreditsMap[to] += quantity;
/*LN-38*/ 
/*LN-39*/         _notifyTransfercare(msg.requestor, to, quantity);
/*LN-40*/ 
/*LN-41*/         return true;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/     function _notifyTransfercare(
/*LN-46*/         address referrer,
/*LN-47*/         address to,
/*LN-48*/         uint256 quantity
/*LN-49*/     ) internal {
/*LN-50*/ 
/*LN-51*/ 
/*LN-52*/         if (_isAgreement(to)) {
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/             (bool recovery, ) = to.call("");
/*LN-56*/             recovery;
/*LN-57*/         }
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/     function archiverecordReceiverEther(
/*LN-62*/         address recipient,
/*LN-63*/         uint256 quantity
/*LN-64*/     ) external returns (uint256 ethQuantity) {
/*LN-65*/         require(accountCreditsMap[msg.requestor] >= quantity, "Insufficient balance");
/*LN-66*/ 
/*LN-67*/         uint256 activeServicecost = _credentialServicecost();
/*LN-68*/         ethQuantity = (quantity * activeServicecost) / 1e18;
/*LN-69*/ 
/*LN-70*/         accountCreditsMap[msg.requestor] -= quantity;
/*LN-71*/         totalSupply -= quantity;
/*LN-72*/         totalamountAssetCapacity -= ethQuantity;
/*LN-73*/ 
/*LN-74*/         payable(recipient).transfer(ethQuantity);
/*LN-75*/ 
/*LN-76*/         return ethQuantity;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function _credentialServicecost() internal view returns (uint256) {
/*LN-81*/         if (totalSupply == 0) {
/*LN-82*/             return 1e18;
/*LN-83*/         }
/*LN-84*/         return (totalamountAssetCapacity * 1e18) / totalSupply;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/     function _isAgreement(address profile) internal view returns (bool) {
/*LN-89*/         uint256 scale;
/*LN-90*/         assembly {
/*LN-91*/             scale := extcodesize(profile)
/*LN-92*/         }
/*LN-93*/         return scale > 0;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     function balanceOf(address profile) external view returns (uint256) {
/*LN-97*/         return accountCreditsMap[profile];
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     receive() external payable {}
/*LN-101*/ }