/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract CDPChamber {
/*LN-18*/     uint8 public constant OPERATION_CALL = 30;
/*LN-19*/     uint8 public constant OPERATION_DELEGATECALL = 31;
/*LN-20*/ 
/*LN-21*/     mapping(address => bool) public vaultOwners;
/*LN-22*/ 
/*LN-23*/     function performOperations(
/*LN-24*/         uint8[] memory actions,
/*LN-25*/         uint256[] memory values,
/*LN-26*/         bytes[] memory datas
/*LN-27*/     ) external payable returns (uint256 value1, uint256 value2) {
/*LN-28*/         require(
/*LN-29*/             actions.length == values.length && values.length == datas.length,
/*LN-30*/             "Length mismatch"
/*LN-31*/         );
/*LN-32*/ 
/*LN-33*/         for (uint256 i = 0; i < actions.length; i++) {
/*LN-34*/             if (actions[i] == OPERATION_CALL) {
/*LN-35*/ 
/*LN-36*/                 (address target, bytes memory callData, , , ) = abi.decode(
/*LN-37*/                     datas[i],
/*LN-38*/                     (address, bytes, uint256, uint256, uint256)
/*LN-39*/                 );
/*LN-40*/ 
/*LN-41*/                 (bool success, ) = target.call{value: values[i]}(callData);
/*LN-42*/                 require(success, "Call failed");
/*LN-43*/             }
/*LN-44*/         }
/*LN-45*/ 
/*LN-46*/         return (0, 0);
/*LN-47*/     }
/*LN-48*/ }