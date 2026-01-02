/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ contract WalletLibrary {
/*LN-5*/     // Owner mapping
/*LN-6*/     mapping(address => bool) public isOwner;
/*LN-7*/     address[] public owners;
/*LN-8*/     uint256 public required; // Number of signatures required
/*LN-9*/ 
/*LN-10*/     // Initialization state
/*LN-11*/     bool public initialized;
/*LN-12*/ 
/*LN-13*/     event OwnerAdded(address indexed owner);
/*LN-14*/     event WalletDestroyed(address indexed destroyer);
/*LN-15*/ 
/*LN-16*/     function initWallet(
/*LN-17*/         address[] memory _owners,
/*LN-18*/         uint256 _required,
/*LN-19*/         uint256 _daylimit
/*LN-20*/     ) public {
/*LN-21*/ 
/*LN-22*/         for (uint i = 0; i < owners.length; i++) {
/*LN-23*/             isOwner[owners[i]] = false;
/*LN-24*/         }
/*LN-25*/         delete owners;
/*LN-26*/ 
/*LN-27*/         // Set new owners
/*LN-28*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-29*/             address owner = _owners[i];
/*LN-30*/             require(owner != address(0), "Invalid owner");
/*LN-31*/             require(!isOwner[owner], "Duplicate owner");
/*LN-32*/ 
/*LN-33*/             isOwner[owner] = true;
/*LN-34*/             owners.push(owner);
/*LN-35*/             emit OwnerAdded(owner);
/*LN-36*/         }
/*LN-37*/ 
/*LN-38*/         required = _required;
/*LN-39*/         initialized = true;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     /**
/*LN-43*/      * @notice Check if an address is an owner
/*LN-44*/      * @param _addr Address to check
/*LN-45*/      * @return bool Whether the address is an owner
/*LN-46*/      */
/*LN-47*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-48*/         return isOwner[_addr];
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     function kill(address payable _to) external {
/*LN-52*/         require(isOwner[msg.sender], "Not an owner");
/*LN-53*/ 
/*LN-54*/         emit WalletDestroyed(msg.sender);
/*LN-55*/ 
/*LN-56*/         selfdestruct(_to);
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     /**
/*LN-60*/      * @notice Example wallet function (simplified)
/*LN-61*/      * @dev All wallet proxies would delegatecall to functions like this
/*LN-62*/      */
/*LN-63*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-64*/         require(isOwner[msg.sender], "Not an owner");
/*LN-65*/ 
/*LN-66*/         (bool success, ) = to.call{value: value}(data);
/*LN-67*/         require(success, "Execution failed");
/*LN-68*/     }
/*LN-69*/ }
/*LN-70*/ 
/*LN-71*/ /**
/*LN-72*/  * Example Wallet Proxy (how real wallets used the library)
/*LN-73*/  */
/*LN-74*/ contract WalletProxy {
/*LN-75*/     // Library address (where all the logic lives)
/*LN-76*/     address public libraryAddress;
/*LN-77*/ 
/*LN-78*/     constructor(address _library) {
/*LN-79*/         libraryAddress = _library;
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     /**
/*LN-83*/      * Fallback function - delegates all calls to the library
/*LN-84*/      * When the library is destroyed via selfdestruct, this breaks completely
/*LN-85*/      */
/*LN-86*/     fallback() external payable {
/*LN-87*/         address lib = libraryAddress;
/*LN-88*/ 
/*LN-89*/         // Delegatecall to library
/*LN-90*/         assembly {
/*LN-91*/             calldatacopy(0, 0, calldatasize())
/*LN-92*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-93*/             returndatacopy(0, 0, returndatasize())
/*LN-94*/ 
/*LN-95*/             switch result
/*LN-96*/             case 0 {
/*LN-97*/                 revert(0, returndatasize())
/*LN-98*/             }
/*LN-99*/             default {
/*LN-100*/                 return(0, returndatasize())
/*LN-101*/             }
/*LN-102*/         }
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     receive() external payable {}
/*LN-106*/ }
/*LN-107*/ 