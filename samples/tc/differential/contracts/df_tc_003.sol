/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Multi-Signature Wallet Library
/*LN-6*/  * @notice Shared library contract for multi-sig wallet functionality
/*LN-7*/  * @dev Used by wallet proxies via delegatecall
/*LN-8*/  */
/*LN-9*/ contract WalletLibrary {
/*LN-10*/     // Owner mapping
/*LN-11*/     mapping(address => bool) public isOwner;
/*LN-12*/     address[] public owners;
/*LN-13*/     uint256 public required;
/*LN-14*/ 
/*LN-15*/     // Initialization state
/*LN-16*/     bool public initialized;
/*LN-17*/ 
/*LN-18*/     event OwnerAdded(address indexed owner);
/*LN-19*/     event WalletDestroyed(address indexed destroyer);
/*LN-20*/ 
/*LN-21*/     /**
/*LN-22*/      * @notice Initialize the wallet with owners
/*LN-23*/      * @param _owners Array of owner addresses
/*LN-24*/      * @param _required Number of required signatures
/*LN-25*/      * @param _daylimit Daily withdrawal limit
/*LN-26*/      */
/*LN-27*/     function initWallet(
/*LN-28*/         address[] memory _owners,
/*LN-29*/         uint256 _required,
/*LN-30*/         uint256 _daylimit
/*LN-31*/     ) public {
/*LN-32*/         require(!initialized, "Already initialized");
/*LN-33*/         initialized = true;
/*LN-34*/ 
/*LN-35*/         // Clear existing owners
/*LN-36*/         for (uint i = 0; i < owners.length; i++) {
/*LN-37*/             isOwner[owners[i]] = false;
/*LN-38*/         }
/*LN-39*/         delete owners;
/*LN-40*/ 
/*LN-41*/         // Set new owners
/*LN-42*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-43*/             address owner = _owners[i];
/*LN-44*/             require(owner != address(0), "Invalid owner");
/*LN-45*/             require(!isOwner[owner], "Duplicate owner");
/*LN-46*/ 
/*LN-47*/             isOwner[owner] = true;
/*LN-48*/             owners.push(owner);
/*LN-49*/             emit OwnerAdded(owner);
/*LN-50*/         }
/*LN-51*/ 
/*LN-52*/         required = _required;
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     /**
/*LN-56*/      * @notice Check if an address is an owner
/*LN-57*/      * @param _addr Address to check
/*LN-58*/      * @return bool Whether the address is an owner
/*LN-59*/      */
/*LN-60*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-61*/         return isOwner[_addr];
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Destroy the contract
/*LN-66*/      * @param _to Address to send remaining funds to
/*LN-67*/      */
/*LN-68*/     function kill(address payable _to) external {
/*LN-69*/         require(isOwner[msg.sender], "Not an owner");
/*LN-70*/         require(initialized, "Not initialized");
/*LN-71*/ 
/*LN-72*/         emit WalletDestroyed(msg.sender);
/*LN-73*/ 
/*LN-74*/         selfdestruct(_to);
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice Execute a transaction
/*LN-79*/      * @param to Target address
/*LN-80*/      * @param value Amount of ETH to send
/*LN-81*/      * @param data Transaction data
/*LN-82*/      */
/*LN-83*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-84*/         require(isOwner[msg.sender], "Not an owner");
/*LN-85*/ 
/*LN-86*/         (bool success, ) = to.call{value: value}(data);
/*LN-87*/         require(success, "Execution failed");
/*LN-88*/     }
/*LN-89*/ }
/*LN-90*/ 
/*LN-91*/ /**
/*LN-92*/  * @title Wallet Proxy
/*LN-93*/  * @notice Proxy contract that delegates to WalletLibrary
/*LN-94*/  */
/*LN-95*/ contract WalletProxy {
/*LN-96*/     address public libraryAddress;
/*LN-97*/ 
/*LN-98*/     constructor(address _library) {
/*LN-99*/         libraryAddress = _library;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     fallback() external payable {
/*LN-103*/         address lib = libraryAddress;
/*LN-104*/ 
/*LN-105*/         assembly {
/*LN-106*/             calldatacopy(0, 0, calldatasize())
/*LN-107*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-108*/             returndatacopy(0, 0, returndatasize())
/*LN-109*/ 
/*LN-110*/             switch result
/*LN-111*/             case 0 {
/*LN-112*/                 revert(0, returndatasize())
/*LN-113*/             }
/*LN-114*/             default {
/*LN-115*/                 return(0, returndatasize())
/*LN-116*/             }
/*LN-117*/         }
/*LN-118*/     }
/*LN-119*/ 
/*LN-120*/     receive() external payable {}
/*LN-121*/ }