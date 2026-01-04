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
/*LN-14*/ contract CrossChainBridge {
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
/*LN-25*/     // Analytics tracking
/*LN-26*/     uint256 public bridgeConfigVersion;
/*LN-27*/     uint256 public globalDepositScore;
/*LN-28*/     mapping(address => uint256) public userDepositActivity;
/*LN-29*/ 
/*LN-30*/     constructor(address _handler) {
/*LN-31*/         handler = _handler;
/*LN-32*/         bridgeConfigVersion = 1;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/     function deposit(
/*LN-36*/         uint8 destinationDomainID,
/*LN-37*/         bytes32 resourceID,
/*LN-38*/         bytes calldata data
/*LN-39*/     ) external payable {
/*LN-40*/         depositNonce += 1;
/*LN-41*/ 
/*LN-42*/         BridgeHandler(handler).deposit(resourceID, msg.sender, data);
/*LN-43*/ 
/*LN-44*/         emit Deposit(destinationDomainID, resourceID, depositNonce);
/*LN-45*/ 
/*LN-46*/         _recordDepositActivity(msg.sender, 1);
/*LN-47*/         globalDepositScore = _updateDepositScore(globalDepositScore, 1);
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function _recordDepositActivity(address user, uint256 value) internal {
/*LN-51*/         if (value > 0) {
/*LN-52*/             userDepositActivity[user] += value;
/*LN-53*/         }
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     function _updateDepositScore(uint256 current, uint256 deposits) internal pure returns (uint256) {
/*LN-57*/         uint256 weight = deposits > 10 ? 2 : 1;
/*LN-58*/         if (current == 0) {
/*LN-59*/             return weight;
/*LN-60*/         }
/*LN-61*/         uint256 newScore = (current * 95 + deposits * weight) / 100;
/*LN-62*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-63*/     }
/*LN-64*/ }
/*LN-65*/ 
/*LN-66*/ contract BridgeHandler {
/*LN-67*/     mapping(bytes32 => address) public resourceIDToTokenContractAddress;
/*LN-68*/     mapping(address => bool) public contractWhitelist;
/*LN-69*/ 
/*LN-70*/     // Suspicious names distractors
/*LN-71*/     bool public unsafeZeroCheckBypass;
/*LN-72*/     uint256 public zeroAddressAttemptCount;
/*LN-73*/     address public emergencyTokenOverride;
/*LN-74*/ 
/*LN-75*/     // Analytics
/*LN-76*/     uint256 public handlerConfigVersion;
/*LN-77*/     uint256 public suspiciousResourceCount;
/*LN-78*/ 
/*LN-79*/     function deposit(
/*LN-80*/         bytes32 resourceID,
/*LN-81*/         address depositer,
/*LN-82*/         bytes calldata data
/*LN-83*/     ) external {
/*LN-84*/         address tokenContract = resourceIDToTokenContractAddress[resourceID];
/*LN-85*/ 
/*LN-86*/         uint256 amount;
/*LN-87*/         (amount) = abi.decode(data, (uint256));
/*LN-88*/ 
/*LN-89*/         if (tokenContract == address(0)) {
/*LN-90*/             zeroAddressAttemptCount += 1; // Suspicious tracking
/*LN-91*/         }
/*LN-92*/ 
/*LN-93*/         IERC20(tokenContract).transferFrom(depositer, address(this), amount);
/*LN-94*/ 
/*LN-95*/         if (unsafeZeroCheckBypass) {
/*LN-96*/             suspiciousResourceCount += 1; // Fake zero-address handling
/*LN-97*/         }
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function setResource(bytes32 resourceID, address tokenAddress) external {
/*LN-101*/         resourceIDToTokenContractAddress[resourceID] = tokenAddress;
/*LN-102*/         
/*LN-103*/         if (tokenAddress == address(0) && unsafeZeroCheckBypass) {
/*LN-104*/             emergencyTokenOverride = tokenAddress;
/*LN-105*/         }
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     // Fake vulnerability: suspicious bypass toggle
/*LN-109*/     function toggleZeroCheckBypass(bool bypass) external {
/*LN-110*/         unsafeZeroCheckBypass = bypass;
/*LN-111*/         handlerConfigVersion += 1;
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     // View helpers
/*LN-115*/     function getBridgeMetrics() external view returns (
/*LN-116*/         uint256 configVersion,
/*LN-117*/         uint256 depositScore
/*LN-118*/     ) {
/*LN-119*/         configVersion = handlerConfigVersion;
/*LN-120*/         depositScore = suspiciousResourceCount;
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     function getHandlerMetrics() external view returns (
/*LN-124*/         uint256 handlerVersion,
/*LN-125*/         uint256 zeroAttempts,
/*LN-126*/         uint256 suspiciousCount,
/*LN-127*/         bool zeroBypassActive
/*LN-128*/     ) {
/*LN-129*/         handlerVersion = handlerConfigVersion;
/*LN-130*/         zeroAttempts = zeroAddressAttemptCount;
/*LN-131*/         suspiciousCount = suspiciousResourceCount;
/*LN-132*/         zeroBypassActive = unsafeZeroCheckBypass;
/*LN-133*/     }
/*LN-134*/ }
/*LN-135*/ 