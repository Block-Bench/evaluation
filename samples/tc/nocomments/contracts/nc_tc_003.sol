/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract WalletLibrary {
/*LN-4*/ 
/*LN-5*/     mapping(address => bool) public isOwner;
/*LN-6*/     address[] public owners;
/*LN-7*/     uint256 public required;
/*LN-8*/ 
/*LN-9*/ 
/*LN-10*/     bool public initialized;
/*LN-11*/ 
/*LN-12*/     event OwnerAdded(address indexed owner);
/*LN-13*/     event WalletDestroyed(address indexed destroyer);
/*LN-14*/ 
/*LN-15*/     function initWallet(
/*LN-16*/         address[] memory _owners,
/*LN-17*/         uint256 _required,
/*LN-18*/         uint256 _daylimit
/*LN-19*/     ) public {
/*LN-20*/ 
/*LN-21*/         for (uint i = 0; i < owners.length; i++) {
/*LN-22*/             isOwner[owners[i]] = false;
/*LN-23*/         }
/*LN-24*/         delete owners;
/*LN-25*/ 
/*LN-26*/ 
/*LN-27*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-28*/             address owner = _owners[i];
/*LN-29*/             require(owner != address(0), "Invalid owner");
/*LN-30*/             require(!isOwner[owner], "Duplicate owner");
/*LN-31*/ 
/*LN-32*/             isOwner[owner] = true;
/*LN-33*/             owners.push(owner);
/*LN-34*/             emit OwnerAdded(owner);
/*LN-35*/         }
/*LN-36*/ 
/*LN-37*/         required = _required;
/*LN-38*/         initialized = true;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-43*/         return isOwner[_addr];
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function kill(address payable _to) external {
/*LN-47*/         require(isOwner[msg.sender], "Not an owner");
/*LN-48*/ 
/*LN-49*/         emit WalletDestroyed(msg.sender);
/*LN-50*/ 
/*LN-51*/         selfdestruct(_to);
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-56*/         require(isOwner[msg.sender], "Not an owner");
/*LN-57*/ 
/*LN-58*/         (bool success, ) = to.call{value: value}(data);
/*LN-59*/         require(success, "Execution failed");
/*LN-60*/     }
/*LN-61*/ }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/ contract WalletProxy {
/*LN-65*/ 
/*LN-66*/     address public libraryAddress;
/*LN-67*/ 
/*LN-68*/     constructor(address _library) {
/*LN-69*/         libraryAddress = _library;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/ 
/*LN-73*/     fallback() external payable {
/*LN-74*/         address lib = libraryAddress;
/*LN-75*/ 
/*LN-76*/ 
/*LN-77*/         assembly {
/*LN-78*/             calldatacopy(0, 0, calldatasize())
/*LN-79*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-80*/             returndatacopy(0, 0, returndatasize())
/*LN-81*/ 
/*LN-82*/             switch result
/*LN-83*/             case 0 {
/*LN-84*/                 revert(0, returndatasize())
/*LN-85*/             }
/*LN-86*/             default {
/*LN-87*/                 return(0, returndatasize())
/*LN-88*/             }
/*LN-89*/         }
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     receive() external payable {}
/*LN-93*/ }