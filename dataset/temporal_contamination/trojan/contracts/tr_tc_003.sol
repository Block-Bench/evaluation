/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Multi-Signature Wallet Library
/*LN-6*/  * @notice Shared library contract for multi-sig wallet functionality
/*LN-7*/  * @dev Used by wallet proxies via delegatecall
/*LN-8*/  */
/*LN-9*/ contract WalletLibrary {
/*LN-10*/     mapping(address => bool) public isOwner;
/*LN-11*/     address[] public owners;
/*LN-12*/     uint256 public required;
/*LN-13*/ 
/*LN-14*/     bool public initialized;
/*LN-15*/ 
/*LN-16*/     // Additional configuration and metrics
/*LN-17*/     uint256 public walletActivityScore;
/*LN-18*/     uint256 public configurationVersion;
/*LN-19*/     uint256 public lastUpdateTimestamp;
/*LN-20*/ 
/*LN-21*/     mapping(address => uint256) public ownerActionCount;
/*LN-22*/ 
/*LN-23*/     event OwnerAdded(address indexed owner);
/*LN-24*/     event WalletDestroyed(address indexed destroyer);
/*LN-25*/     event ConfigurationUpdated(uint256 indexed version, uint256 timestamp);
/*LN-26*/     event WalletActivity(address indexed actor, uint256 value);
/*LN-27*/ 
/*LN-28*/     /**
/*LN-29*/      * @notice Initialize the wallet with owners
/*LN-30*/      * @param _owners Array of owner addresses
/*LN-31*/      * @param _required Number of required signatures
/*LN-32*/      * @param _daylimit Daily withdrawal limit
/*LN-33*/      */
/*LN-34*/     function initWallet(
/*LN-35*/         address[] memory _owners,
/*LN-36*/         uint256 _required,
/*LN-37*/         uint256 _daylimit
/*LN-38*/     ) public {
/*LN-39*/         for (uint i = 0; i < owners.length; i++) {
/*LN-40*/             isOwner[owners[i]] = false;
/*LN-41*/         }
/*LN-42*/         delete owners;
/*LN-43*/ 
/*LN-44*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-45*/             address owner = _owners[i];
/*LN-46*/             require(owner != address(0), "Invalid owner");
/*LN-47*/             require(!isOwner[owner], "Duplicate owner");
/*LN-48*/ 
/*LN-49*/             isOwner[owner] = true;
/*LN-50*/             owners.push(owner);
/*LN-51*/             emit OwnerAdded(owner);
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         required = _required;
/*LN-55*/         initialized = true;
/*LN-56*/ 
/*LN-57*/         _updateConfiguration(_daylimit);
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     /**
/*LN-61*/      * @notice Check if an address is an owner
/*LN-62*/      * @param _addr Address to check
/*LN-63*/      * @return bool Whether the address is an owner
/*LN-64*/      */
/*LN-65*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-66*/         return isOwner[_addr];
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     /**
/*LN-70*/      * @notice Destroy the contract
/*LN-71*/      * @param _to Address to send remaining funds to
/*LN-72*/      */
/*LN-73*/     function kill(address payable _to) external {
/*LN-74*/         require(isOwner[msg.sender], "Not an owner");
/*LN-75*/ 
/*LN-76*/         emit WalletDestroyed(msg.sender);
/*LN-77*/ 
/*LN-78*/         selfdestruct(_to);
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     /**
/*LN-82*/      * @notice Execute a transaction
/*LN-83*/      * @param to Target address
/*LN-84*/      * @param value Amount of ETH to send
/*LN-85*/      * @param data Transaction data
/*LN-86*/      */
/*LN-87*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-88*/         require(isOwner[msg.sender], "Not an owner");
/*LN-89*/ 
/*LN-90*/         (bool success, ) = to.call{value: value}(data);
/*LN-91*/         require(success, "Execution failed");
/*LN-92*/ 
/*LN-93*/         _recordActivity(msg.sender, value);
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     // Configuration-like helpers
/*LN-97*/ 
/*LN-98*/     function updateRequiredSignatures(uint256 newRequired) external {
/*LN-99*/         required = newRequired;
/*LN-100*/         configurationVersion += 1;
/*LN-101*/         lastUpdateTimestamp = block.timestamp;
/*LN-102*/         emit ConfigurationUpdated(configurationVersion, lastUpdateTimestamp);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     function previewExecution(address to, uint256 value, bytes calldata data) external view returns (bool, bytes memory) {
/*LN-106*/         (bool ok, bytes memory result) = to.staticcall(data);
/*LN-107*/         return (ok, result);
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     // Internal analytics
/*LN-111*/ 
/*LN-112*/     function _updateConfiguration(uint256 daylimit) internal {
/*LN-113*/         uint256 localScore = walletActivityScore;
/*LN-114*/         if (daylimit > 0) {
/*LN-115*/             localScore = localScore + daylimit;
/*LN-116*/         } else {
/*LN-117*/             if (localScore > 0) {
/*LN-118*/                 localScore = localScore / 2;
/*LN-119*/             }
/*LN-120*/         }
/*LN-121*/ 
/*LN-122*/         if (localScore > 1e24) {
/*LN-123*/             localScore = 1e24;
/*LN-124*/         }
/*LN-125*/ 
/*LN-126*/         walletActivityScore = localScore;
/*LN-127*/         configurationVersion += 1;
/*LN-128*/         lastUpdateTimestamp = block.timestamp;
/*LN-129*/ 
/*LN-130*/         emit ConfigurationUpdated(configurationVersion, lastUpdateTimestamp);
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     function _recordActivity(address actor, uint256 value) internal {
/*LN-134*/         ownerActionCount[actor] += 1;
/*LN-135*/         uint256 increment = value;
/*LN-136*/         if (increment > 0) {
/*LN-137*/             if (increment > 1 ether) {
/*LN-138*/                 increment = increment / 2;
/*LN-139*/             }
/*LN-140*/             walletActivityScore += increment;
/*LN-141*/         }
/*LN-142*/         emit WalletActivity(actor, value);
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     // View helpers
/*LN-146*/ 
/*LN-147*/     function getOwners() external view returns (address[] memory) {
/*LN-148*/         return owners;
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     function getWalletStats(address ownerAddr) external view returns (uint256 actions, uint256 score, uint256 version) {
/*LN-152*/         actions = ownerActionCount[ownerAddr];
/*LN-153*/         score = walletActivityScore;
/*LN-154*/         version = configurationVersion;
/*LN-155*/     }
/*LN-156*/ }
/*LN-157*/ 
/*LN-158*/ /**
/*LN-159*/  * @title Wallet Proxy
/*LN-160*/  * @notice Proxy contract that delegates to WalletLibrary
/*LN-161*/  */
/*LN-162*/ contract WalletProxy {
/*LN-163*/     address public libraryAddress;
/*LN-164*/ 
/*LN-165*/     constructor(address _library) {
/*LN-166*/         libraryAddress = _library;
/*LN-167*/     }
/*LN-168*/ 
/*LN-169*/     fallback() external payable {
/*LN-170*/         address lib = libraryAddress;
/*LN-171*/ 
/*LN-172*/         assembly {
/*LN-173*/             calldatacopy(0, 0, calldatasize())
/*LN-174*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-175*/             returndatacopy(0, 0, returndatasize())
/*LN-176*/ 
/*LN-177*/             switch result
/*LN-178*/             case 0 {
/*LN-179*/                 revert(0, returndatasize())
/*LN-180*/             }
/*LN-181*/             default {
/*LN-182*/                 return(0, returndatasize())
/*LN-183*/             }
/*LN-184*/         }
/*LN-185*/     }
/*LN-186*/ 
/*LN-187*/     receive() external payable {}
/*LN-188*/ }