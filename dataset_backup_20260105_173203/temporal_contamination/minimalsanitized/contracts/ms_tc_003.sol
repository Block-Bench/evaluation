/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ contract ParityWalletLibrary {
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
/*LN-22*/ 
/*LN-23*/         
/*LN-24*/         
/*LN-25*/ 
/*LN-26*/         
/*LN-27*/         for (uint i = 0; i < owners.length; i++) {
/*LN-28*/             isOwner[owners[i]] = false;
/*LN-29*/         }
/*LN-30*/         delete owners;
/*LN-31*/ 
/*LN-32*/         // Set new owners
/*LN-33*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-34*/             address owner = _owners[i];
/*LN-35*/             require(owner != address(0), "Invalid owner");
/*LN-36*/             require(!isOwner[owner], "Duplicate owner");
/*LN-37*/ 
/*LN-38*/             isOwner[owner] = true;
/*LN-39*/             owners.push(owner);
/*LN-40*/             emit OwnerAdded(owner);
/*LN-41*/         }
/*LN-42*/ 
/*LN-43*/         required = _required;
/*LN-44*/         initialized = true;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     /**
/*LN-48*/      * @notice Check if an address is an owner
/*LN-49*/      * @param _addr Address to check
/*LN-50*/      * @return bool Whether the address is an owner
/*LN-51*/      */
/*LN-52*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-53*/         return isOwner[_addr];
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     function kill(address payable _to) external {
/*LN-57*/         require(isOwner[msg.sender], "Not an owner");
/*LN-58*/ 
/*LN-59*/         emit WalletDestroyed(msg.sender);
/*LN-60*/ 
/*LN-61*/         
/*LN-62*/         selfdestruct(_to);
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     /**
/*LN-66*/      * @notice Example wallet function (simplified)
/*LN-67*/      * @dev All wallet proxies would delegatecall to functions like this
/*LN-68*/      */
/*LN-69*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-70*/         require(isOwner[msg.sender], "Not an owner");
/*LN-71*/ 
/*LN-72*/         (bool success, ) = to.call{value: value}(data);
/*LN-73*/         require(success, "Execution failed");
/*LN-74*/     }
/*LN-75*/ }
/*LN-76*/ 
/*LN-77*/ /**
/*LN-78*/  * Example Wallet Proxy (how real wallets used the library)
/*LN-79*/  */
/*LN-80*/ contract ParityWalletProxy {
/*LN-81*/     // Library address (where all the logic lives)
/*LN-82*/     address public libraryAddress;
/*LN-83*/ 
/*LN-84*/     constructor(address _library) {
/*LN-85*/         libraryAddress = _library;
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     /**
/*LN-89*/      * Fallback function - delegates all calls to the library
/*LN-90*/      * When the library is destroyed via selfdestruct, this breaks completely
/*LN-91*/      */
/*LN-92*/     fallback() external payable {
/*LN-93*/         address lib = libraryAddress;
/*LN-94*/ 
/*LN-95*/         // Delegatecall to library
/*LN-96*/         assembly {
/*LN-97*/             calldatacopy(0, 0, calldatasize())
/*LN-98*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-99*/             returndatacopy(0, 0, returndatasize())
/*LN-100*/ 
/*LN-101*/             switch result
/*LN-102*/             case 0 {
/*LN-103*/                 revert(0, returndatasize())
/*LN-104*/             }
/*LN-105*/             default {
/*LN-106*/                 return(0, returndatasize())
/*LN-107*/             }
/*LN-108*/         }
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     receive() external payable {}
/*LN-112*/ }
/*LN-113*/ 