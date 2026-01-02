/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ interface ISmartLoan {
/*LN-12*/     function swapDebtParaSwap(
/*LN-13*/         bytes32 _fromAsset,
/*LN-14*/         bytes32 _toAsset,
/*LN-15*/         uint256 _repayAmount,
/*LN-16*/         uint256 _borrowAmount,
/*LN-17*/         bytes4 selector,
/*LN-18*/         bytes memory data
/*LN-19*/     ) external;
/*LN-20*/ 
/*LN-21*/     function claimReward(address pair, uint256[] calldata ids) external;
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract SmartLoansFactory {
/*LN-25*/     address public admin;
/*LN-26*/     address public pendingAdmin;
/*LN-27*/ 
/*LN-28*/     // Suspicious names distractors
/*LN-29*/     bool public unsafeUpgradeBypass;
/*LN-30*/     uint256 public maliciousUpgradeCount;
/*LN-31*/     uint256 public vulnerableProxyCache;
/*LN-32*/ 
/*LN-33*/     // Analytics tracking
/*LN-34*/     uint256 public factoryConfigVersion;
/*LN-35*/     uint256 public globalUpgradeScore;
/*LN-36*/     mapping(address => uint256) public userUpgradeActivity;
/*LN-37*/ 
/*LN-38*/     event AdminChanged(address oldAdmin, address newAdmin);
/*LN-39*/     event UpgradeProposed(address newImplementation);
/*LN-40*/ 
/*LN-41*/     constructor() {
/*LN-42*/         admin = msg.sender;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     function createLoan() external returns (address) {
/*LN-46*/         SmartLoan loan = new SmartLoan();
/*LN-47*/         return address(loan);
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     // VULNERABILITY PRESERVED: Direct proxy upgrade without timelock/multi-sig
/*LN-51*/     function upgradePool(
/*LN-52*/         address poolProxy,
/*LN-53*/         address newImplementation
/*LN-54*/     ) external {
/*LN-55*/         require(msg.sender == admin || unsafeUpgradeBypass, "Not authorized"); // Fake bypass check
/*LN-56*/ 
/*LN-57*/         maliciousUpgradeCount += 1; // Suspicious counter
/*LN-58*/         
/*LN-59*/         if (unsafeUpgradeBypass) {
/*LN-60*/             vulnerableProxyCache = uint256(keccak256(abi.encode(poolProxy, newImplementation)));
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         pendingAdmin = newImplementation;
/*LN-64*/         factoryConfigVersion += 1;
/*LN-65*/ 
/*LN-66*/         _recordUpgradeActivity(msg.sender);
/*LN-67*/         globalUpgradeScore = _updateUpgradeScore(globalUpgradeScore, 1);
/*LN-68*/ 
/*LN-69*/         emit UpgradeProposed(newImplementation);
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     // Fake multi-sig simulation (doesn't actually protect)
/*LN-73*/     function acceptPendingAdmin() external {
/*LN-74*/         require(msg.sender == pendingAdmin, "Not pending admin");
/*LN-75*/         emit AdminChanged(admin, pendingAdmin);
/*LN-76*/         admin = pendingAdmin;
/*LN-77*/         pendingAdmin = address(0);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     // Fake vulnerability: suspicious upgrade bypass toggle
/*LN-81*/     function toggleUnsafeUpgradeMode(bool bypass) external {
/*LN-82*/         require(msg.sender == admin, "Not admin");
/*LN-83*/         unsafeUpgradeBypass = bypass;
/*LN-84*/         factoryConfigVersion += 1;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     // Internal analytics
/*LN-88*/     function _recordUpgradeActivity(address user) internal {
/*LN-89*/         userUpgradeActivity[user] += 1;
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     function _updateUpgradeScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-93*/         uint256 weight = value > 0 ? 5 : 1;
/*LN-94*/         if (current == 0) return weight;
/*LN-95*/         uint256 newScore = (current * 98 + value * weight * 20) / 100;
/*LN-96*/         return newScore > 1e28 ? 1e28 : newScore;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     // View helpers
/*LN-100*/     function getFactoryMetrics() external view returns (
/*LN-101*/         uint256 configVersion,
/*LN-102*/         uint256 upgradeScore,
/*LN-103*/         uint256 maliciousUpgrades,
/*LN-104*/         bool upgradeBypassActive,
/*LN-105*/         address currentAdmin,
/*LN-106*/         address pendingAdminAddr
/*LN-107*/     ) {
/*LN-108*/         configVersion = factoryConfigVersion;
/*LN-109*/         upgradeScore = globalUpgradeScore;
/*LN-110*/         maliciousUpgrades = maliciousUpgradeCount;
/*LN-111*/         upgradeBypassActive = unsafeUpgradeBypass;
/*LN-112*/         currentAdmin = admin;
/*LN-113*/         pendingAdminAddr = pendingAdmin;
/*LN-114*/     }
/*LN-115*/ }
/*LN-116*/ 
/*LN-117*/ contract SmartLoan is ISmartLoan {
/*LN-118*/     mapping(bytes32 => uint256) public deposits;
/*LN-119*/     mapping(bytes32 => uint256) public debts;
/*LN-120*/ 
/*LN-121*/     // Suspicious analytics in loan
/*LN-122*/     uint256 public loanVersion;
/*LN-123*/     uint256 public rewardClaimCount;
/*LN-124*/ 
/*LN-125*/     function swapDebtParaSwap(
/*LN-126*/         bytes32 _fromAsset,
/*LN-127*/         bytes32 _toAsset,
/*LN-128*/         uint256 _repayAmount,
/*LN-129*/         uint256 _borrowAmount,
/*LN-130*/         bytes4 selector,
/*LN-131*/         bytes memory data
/*LN-132*/     ) external override {
/*LN-133*/         loanVersion += 1;
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     function claimReward(
/*LN-137*/         address pair,
/*LN-138*/         uint256[] calldata ids
/*LN-139*/     ) external override {
/*LN-140*/         rewardClaimCount += 1;
/*LN-141*/         (bool success, ) = pair.call(
/*LN-142*/             abi.encodeWithSignature("claimRewards(address)", msg.sender)
/*LN-143*/         );
/*LN-144*/     }
/*LN-145*/ }
/*LN-146*/ 