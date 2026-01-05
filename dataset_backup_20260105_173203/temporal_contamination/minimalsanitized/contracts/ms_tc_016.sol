/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transferFrom(
/*LN-6*/         address from,
/*LN-7*/         address to,
/*LN-8*/         uint256 amount
/*LN-9*/     ) external returns (bool);
/*LN-10*/ 
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract QBridge {
/*LN-15*/     address public handler;
/*LN-16*/ 
/*LN-17*/     event Deposit(
/*LN-18*/         uint8 destinationDomainID,
/*LN-19*/         bytes32 resourceID,
/*LN-20*/         uint64 depositNonce
/*LN-21*/     );
/*LN-22*/ 
/*LN-23*/     uint64 public depositNonce;
/*LN-24*/ 
/*LN-25*/     constructor(address _handler) {
/*LN-26*/         handler = _handler;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     /**
/*LN-30*/      * @notice Initiates a bridge deposit
/*LN-31*/      */
/*LN-32*/     function deposit(
/*LN-33*/         uint8 destinationDomainID,
/*LN-34*/         bytes32 resourceID,
/*LN-35*/         bytes calldata data
/*LN-36*/     ) external payable {
/*LN-37*/         depositNonce += 1;
/*LN-38*/ 
/*LN-39*/         QBridgeHandler(handler).deposit(resourceID, msg.sender, data);
/*LN-40*/ 
/*LN-41*/         emit Deposit(destinationDomainID, resourceID, depositNonce);
/*LN-42*/     }
/*LN-43*/ }
/*LN-44*/ 
/*LN-45*/ contract QBridgeHandler {
/*LN-46*/     mapping(bytes32 => address) public resourceIDToTokenContractAddress;
/*LN-47*/     mapping(address => bool) public contractWhitelist;
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      * @notice Process bridge deposit
/*LN-51*/      */
/*LN-52*/     function deposit(
/*LN-53*/         bytes32 resourceID,
/*LN-54*/         address depositer,
/*LN-55*/         bytes calldata data
/*LN-56*/     ) external {
/*LN-57*/         address tokenContract = resourceIDToTokenContractAddress[resourceID];
/*LN-58*/ 
/*LN-59*/         
/*LN-60*/         
/*LN-61*/ 
/*LN-62*/         uint256 amount;
/*LN-63*/         (amount) = abi.decode(data, (uint256));
/*LN-64*/ 
/*LN-65*/         
/*LN-66*/         
/*LN-67*/         IERC20(tokenContract).transferFrom(depositer, address(this), amount);
/*LN-68*/ 
/*LN-69*/         
/*LN-70*/         
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     /**
/*LN-74*/      * @notice Set resource ID to token mapping
/*LN-75*/      */
/*LN-76*/     function setResource(bytes32 resourceID, address tokenAddress) external {
/*LN-77*/         resourceIDToTokenContractAddress[resourceID] = tokenAddress;
/*LN-78*/ 
/*LN-79*/         
/*LN-80*/     }
/*LN-81*/ }
/*LN-82*/ 