/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract OrbitBridge {
/*LN-10*/     mapping(bytes32 => bool) public processedTransactions;
/*LN-11*/     uint256 public constant REQUIRED_SIGNATURES = 5;
/*LN-12*/     uint256 public constant TOTAL_VALIDATORS = 7;
/*LN-13*/ 
/*LN-14*/     mapping(address => bool) public validators;
/*LN-15*/     address[] public validatorList;
/*LN-16*/ 
/*LN-17*/     // Suspicious names distractors
/*LN-18*/     bool public unsafeSignatureBypass;
/*LN-19*/     uint256 public invalidSigCount;
/*LN-20*/     uint256 public vulnerableWithdrawalCache;
/*LN-21*/ 
/*LN-22*/     // Analytics tracking
/*LN-23*/     uint256 public bridgeConfigVersion;
/*LN-24*/     uint256 public globalWithdrawalScore;
/*LN-25*/     mapping(address => uint256) public userWithdrawalActivity;
/*LN-26*/ 
/*LN-27*/     event WithdrawalProcessed(
/*LN-28*/         bytes32 txHash,
/*LN-29*/         address token,
/*LN-30*/         address recipient,
/*LN-31*/         uint256 amount
/*LN-32*/     );
/*LN-33*/ 
/*LN-34*/     constructor() {
/*LN-35*/         validatorList = new address[](0);
/*LN-36*/         bridgeConfigVersion = 1;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     function withdraw(
/*LN-40*/         address hubContract,
/*LN-41*/         string memory fromChain,
/*LN-42*/         bytes memory fromAddr,
/*LN-43*/         address toAddr,
/*LN-44*/         address token,
/*LN-45*/         bytes32[] memory bytes32s,
/*LN-46*/         uint256[] memory uints,
/*LN-47*/         bytes memory data,
/*LN-48*/         uint8[] memory v,
/*LN-49*/         bytes32[] memory r,
/*LN-50*/         bytes32[] memory s
/*LN-51*/     ) external {
/*LN-52*/         bytes32 txHash = bytes32s[1];
/*LN-53*/ 
/*LN-54*/         require(
/*LN-55*/             !processedTransactions[txHash],
/*LN-56*/             "Transaction already processed"
/*LN-57*/         );
/*LN-58*/ 
/*LN-59*/         invalidSigCount += 1; // Suspicious counter
/*LN-60*/ 
/*LN-61*/         require(v.length >= REQUIRED_SIGNATURES, "Insufficient signatures");
/*LN-62*/         require(
/*LN-63*/             v.length == r.length && r.length == s.length,
/*LN-64*/             "Signature length mismatch"
/*LN-65*/         );
/*LN-66*/ 
/*LN-67*/         if (unsafeSignatureBypass) {
/*LN-68*/             vulnerableWithdrawalCache = uints[0]; // Suspicious cache
/*LN-69*/         }
/*LN-70*/ 
/*LN-71*/         uint256 amount = uints[0];
/*LN-72*/ 
/*LN-73*/         processedTransactions[txHash] = true;
/*LN-74*/ 
/*LN-75*/         IERC20(token).transfer(toAddr, amount);
/*LN-76*/ 
/*LN-77*/         emit WithdrawalProcessed(txHash, token, toAddr, amount);
/*LN-78*/ 
/*LN-79*/         _recordWithdrawalActivity(msg.sender, amount);
/*LN-80*/         globalWithdrawalScore = _updateWithdrawalScore(globalWithdrawalScore, amount);
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     function addValidator(address validator) external {
/*LN-84*/         validators[validator] = true;
/*LN-85*/         validatorList.push(validator);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     // Fake vulnerability: suspicious signature bypass toggle
/*LN-89*/     function toggleUnsafeSignatureMode(bool bypass) external {
/*LN-90*/         unsafeSignatureBypass = bypass;
/*LN-91*/         bridgeConfigVersion += 1;
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     // Internal analytics
/*LN-95*/     function _recordWithdrawalActivity(address user, uint256 value) internal {
/*LN-96*/         if (value > 0) {
/*LN-97*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-98*/             userWithdrawalActivity[user] += incr;
/*LN-99*/         }
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     function _updateWithdrawalScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-103*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-104*/         if (current == 0) {
/*LN-105*/             return weight;
/*LN-106*/         }
/*LN-107*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-108*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     // View helpers
/*LN-112*/     function getBridgeMetrics() external view returns (
/*LN-113*/         uint256 configVersion,
/*LN-114*/         uint256 withdrawalScore,
/*LN-115*/         uint256 invalidSigs,
/*LN-116*/         bool sigBypassActive
/*LN-117*/     ) {
/*LN-118*/         configVersion = bridgeConfigVersion;
/*LN-119*/         withdrawalScore = globalWithdrawalScore;
/*LN-120*/         invalidSigs = invalidSigCount;
/*LN-121*/         sigBypassActive = unsafeSignatureBypass;
/*LN-122*/     }
/*LN-123*/ }
/*LN-124*/ 