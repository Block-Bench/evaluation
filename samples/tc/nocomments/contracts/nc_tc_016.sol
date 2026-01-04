/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transferFrom(
/*LN-5*/         address from,
/*LN-6*/         address to,
/*LN-7*/         uint256 amount
/*LN-8*/     ) external returns (bool);
/*LN-9*/ 
/*LN-10*/     function balanceOf(address account) external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ contract QuantumBridge {
/*LN-14*/     address public handler;
/*LN-15*/ 
/*LN-16*/     event Deposit(
/*LN-17*/         uint8 destinationDomainID,
/*LN-18*/         bytes32 resourceID,
/*LN-19*/         uint64 depositNonce
/*LN-20*/     );
/*LN-21*/ 
/*LN-22*/     uint64 public depositNonce;
/*LN-23*/ 
/*LN-24*/     constructor(address _handler) {
/*LN-25*/         handler = _handler;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/ 
/*LN-29*/     function deposit(
/*LN-30*/         uint8 destinationDomainID,
/*LN-31*/         bytes32 resourceID,
/*LN-32*/         bytes calldata data
/*LN-33*/     ) external payable {
/*LN-34*/         depositNonce += 1;
/*LN-35*/ 
/*LN-36*/         BridgeHandler(handler).deposit(resourceID, msg.sender, data);
/*LN-37*/ 
/*LN-38*/         emit Deposit(destinationDomainID, resourceID, depositNonce);
/*LN-39*/     }
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ contract BridgeHandler {
/*LN-43*/     mapping(bytes32 => address) public resourceIDToTokenContractAddress;
/*LN-44*/     mapping(address => bool) public contractWhitelist;
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/     function deposit(
/*LN-48*/         bytes32 resourceID,
/*LN-49*/         address depositer,
/*LN-50*/         bytes calldata data
/*LN-51*/     ) external {
/*LN-52*/         address tokenContract = resourceIDToTokenContractAddress[resourceID];
/*LN-53*/ 
/*LN-54*/         uint256 amount;
/*LN-55*/         (amount) = abi.decode(data, (uint256));
/*LN-56*/ 
/*LN-57*/         IERC20(tokenContract).transferFrom(depositer, address(this), amount);
/*LN-58*/ 
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/     function setResource(bytes32 resourceID, address tokenAddress) external {
/*LN-63*/         resourceIDToTokenContractAddress[resourceID] = tokenAddress;
/*LN-64*/ 
/*LN-65*/     }
/*LN-66*/ }