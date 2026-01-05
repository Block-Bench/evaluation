/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract SenecaChamber {
/*LN-16*/     uint8 public constant OPERATION_CALL = 30;
/*LN-17*/     uint8 public constant OPERATION_DELEGATECALL = 31;
/*LN-18*/ 
/*LN-19*/     mapping(address => bool) public vaultOwners;
/*LN-20*/     mapping(address => bool) public allowedTargets;
/*LN-21*/     mapping(bytes4 => bool) public allowedSelectors;
/*LN-22*/     address public admin;
/*LN-23*/ 
/*LN-24*/     constructor() {
/*LN-25*/         admin = msg.sender;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     modifier onlyAdmin() {
/*LN-29*/         require(msg.sender == admin, "Not admin");
/*LN-30*/         _;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function addAllowedTarget(address target) external onlyAdmin {
/*LN-34*/         allowedTargets[target] = true;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function addAllowedSelector(bytes4 selector) external onlyAdmin {
/*LN-38*/         allowedSelectors[selector] = true;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     function performOperations(
/*LN-42*/         uint8[] memory actions,
/*LN-43*/         uint256[] memory values,
/*LN-44*/         bytes[] memory datas
/*LN-45*/     ) external payable returns (uint256 value1, uint256 value2) {
/*LN-46*/         require(
/*LN-47*/             actions.length == values.length && values.length == datas.length,
/*LN-48*/             "Length mismatch"
/*LN-49*/         );
/*LN-50*/ 
/*LN-51*/         for (uint256 i = 0; i < actions.length; i++) {
/*LN-52*/             if (actions[i] == OPERATION_CALL) {
/*LN-53*/                 (address target, bytes memory callData, , , ) = abi.decode(
/*LN-54*/                     datas[i],
/*LN-55*/                     (address, bytes, uint256, uint256, uint256)
/*LN-56*/                 );
/*LN-57*/ 
/*LN-58*/                 require(allowedTargets[target], "Target not allowed");
/*LN-59*/                 bytes4 selector = bytes4(callData);
/*LN-60*/                 require(allowedSelectors[selector], "Selector not allowed");
/*LN-61*/ 
/*LN-62*/                 (bool success, ) = target.call{value: values[i]}(callData);
/*LN-63*/                 require(success, "Call failed");
/*LN-64*/             }
/*LN-65*/         }
/*LN-66*/ 
/*LN-67*/         return (0, 0);
/*LN-68*/     }
/*LN-69*/ }
/*LN-70*/ 