/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ contract CDPChamber {
/*LN-19*/     uint8 public constant OPERATION_CALL = 30;
/*LN-20*/     uint8 public constant OPERATION_DELEGATECALL = 31;
/*LN-21*/ 
/*LN-22*/     mapping(address => bool) public vaultOwners;
/*LN-23*/ 
/*LN-24*/     function performOperations(
/*LN-25*/         uint8[] memory actions,
/*LN-26*/         uint256[] memory values,
/*LN-27*/         bytes[] memory datas
/*LN-28*/     ) external payable returns (uint256 value1, uint256 value2) {
/*LN-29*/         require(
/*LN-30*/             actions.length == values.length && values.length == datas.length,
/*LN-31*/             "Length mismatch"
/*LN-32*/         );
/*LN-33*/ 
/*LN-34*/         for (uint256 i = 0; i < actions.length; i++) {
/*LN-35*/             if (actions[i] == OPERATION_CALL) {
/*LN-36*/                 // Decode target from user-provided data
/*LN-37*/                 (address target, bytes memory callData, , , ) = abi.decode(
/*LN-38*/                     datas[i],
/*LN-39*/                     (address, bytes, uint256, uint256, uint256)
/*LN-40*/                 );
/*LN-41*/ 
/*LN-42*/                 (bool success, ) = target.call{value: values[i]}(callData);
/*LN-43*/                 require(success, "Call failed");
/*LN-44*/             }
/*LN-45*/         }
/*LN-46*/ 
/*LN-47*/         return (0, 0);
/*LN-48*/     }
/*LN-49*/ }
/*LN-50*/ 