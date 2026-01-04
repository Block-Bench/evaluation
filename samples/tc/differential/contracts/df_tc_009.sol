/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Pool Contract
/*LN-6*/  * @notice Manages token supplies and withdrawals
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC777 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IERC1820Registry {
/*LN-16*/     function setInterfaceImplementer(
/*LN-17*/         address account,
/*LN-18*/         bytes32 interfaceHash,
/*LN-19*/         address implementer
/*LN-20*/     ) external;
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ contract LendingPool {
/*LN-24*/     mapping(address => mapping(address => uint256)) public supplied;
/*LN-25*/     mapping(address => uint256) public totalSupplied;
/*LN-26*/ 
/*LN-27*/     function supply(address asset, uint256 amount) external returns (uint256) {
/*LN-28*/         IERC777 token = IERC777(asset);
/*LN-29*/ 
/*LN-30*/         require(token.transfer(address(this), amount), "Transfer failed");
/*LN-31*/ 
/*LN-32*/         supplied[msg.sender][asset] += amount;
/*LN-33*/         totalSupplied[asset] += amount;
/*LN-34*/ 
/*LN-35*/         return amount;
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     function withdraw(
/*LN-39*/         address asset,
/*LN-40*/         uint256 requestedAmount
/*LN-41*/     ) external returns (uint256) {
/*LN-42*/         uint256 userBalance = supplied[msg.sender][asset];
/*LN-43*/         require(userBalance > 0, "No balance");
/*LN-44*/ 
/*LN-45*/         uint256 withdrawAmount = requestedAmount;
/*LN-46*/         if (requestedAmount == type(uint256).max) {
/*LN-47*/             withdrawAmount = userBalance;
/*LN-48*/         }
/*LN-49*/         require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-50*/ 
/*LN-51*/         supplied[msg.sender][asset] -= withdrawAmount;
/*LN-52*/         totalSupplied[asset] -= withdrawAmount;
/*LN-53*/ 
/*LN-54*/         IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-55*/ 
/*LN-56*/         return withdrawAmount;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     function getSupplied(
/*LN-60*/         address user,
/*LN-61*/         address asset
/*LN-62*/     ) external view returns (uint256) {
/*LN-63*/         return supplied[user][asset];
/*LN-64*/     }
/*LN-65*/ }
/*LN-66*/ 