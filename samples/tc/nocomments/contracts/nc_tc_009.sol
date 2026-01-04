/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC777 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface IERC1820Registry {
/*LN-10*/     function setInterfaceImplementer(
/*LN-11*/         address account,
/*LN-12*/         bytes32 interfaceHash,
/*LN-13*/         address implementer
/*LN-14*/     ) external;
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract LendingPool {
/*LN-18*/     mapping(address => mapping(address => uint256)) public supplied;
/*LN-19*/     mapping(address => uint256) public totalSupplied;
/*LN-20*/ 
/*LN-21*/ 
/*LN-22*/     function supply(address asset, uint256 amount) external returns (uint256) {
/*LN-23*/         IERC777 token = IERC777(asset);
/*LN-24*/ 
/*LN-25*/ 
/*LN-26*/         require(token.transfer(address(this), amount), "Transfer failed");
/*LN-27*/ 
/*LN-28*/ 
/*LN-29*/         supplied[msg.sender][asset] += amount;
/*LN-30*/         totalSupplied[asset] += amount;
/*LN-31*/ 
/*LN-32*/         return amount;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/ 
/*LN-36*/     function withdraw(
/*LN-37*/         address asset,
/*LN-38*/         uint256 requestedAmount
/*LN-39*/     ) external returns (uint256) {
/*LN-40*/         uint256 userBalance = supplied[msg.sender][asset];
/*LN-41*/         require(userBalance > 0, "No balance");
/*LN-42*/ 
/*LN-43*/ 
/*LN-44*/         uint256 withdrawAmount = requestedAmount;
/*LN-45*/         if (requestedAmount == type(uint256).max) {
/*LN-46*/             withdrawAmount = userBalance;
/*LN-47*/         }
/*LN-48*/         require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-49*/ 
/*LN-50*/ 
/*LN-51*/         IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-52*/ 
/*LN-53*/ 
/*LN-54*/         supplied[msg.sender][asset] -= withdrawAmount;
/*LN-55*/         totalSupplied[asset] -= withdrawAmount;
/*LN-56*/ 
/*LN-57*/         return withdrawAmount;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/     function getSupplied(
/*LN-62*/         address user,
/*LN-63*/         address asset
/*LN-64*/     ) external view returns (uint256) {
/*LN-65*/         return supplied[user][asset];
/*LN-66*/     }
/*LN-67*/ }