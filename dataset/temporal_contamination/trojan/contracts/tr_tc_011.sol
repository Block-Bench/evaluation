/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Pool Contract
/*LN-6*/  * @notice Manages token supplies and withdrawals
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC777 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IERC1820Registry {
/*LN-16*/     function setInterfaceImplementer(
/*LN-17*/         address account,
/*LN-18*/         bytes32 interfaceHash,
/*LN-19*/         address implementer
/*LN-20*/     ) external;
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ contract LendingPool {
/*LN-24*/     mapping(address => mapping(address => uint256)) public supplied;
/*LN-25*/     mapping(address => uint256) public totalSupplied;
/*LN-26*/ 
/*LN-27*/     // Additional configuration and analytics
/*LN-28*/     uint256 public poolConfigVersion;
/*LN-29*/     uint256 public lastConfigUpdate;
/*LN-30*/     uint256 public globalActivityScore;
/*LN-31*/     mapping(address => uint256) public userActivityScore;
/*LN-32*/     mapping(address => uint256) public userWithdrawCount;
/*LN-33*/ 
/*LN-34*/     function supply(address asset, uint256 amount) external returns (uint256) {
/*LN-35*/         IERC777 token = IERC777(asset);
/*LN-36*/ 
/*LN-37*/         require(token.transfer(address(this), amount), "Transfer failed");
/*LN-38*/ 
/*LN-39*/         supplied[msg.sender][asset] += amount;
/*LN-40*/         totalSupplied[asset] += amount;
/*LN-41*/ 
/*LN-42*/         _recordActivity(msg.sender, amount);
/*LN-43*/ 
/*LN-44*/         return amount;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     function withdraw(
/*LN-48*/         address asset,
/*LN-49*/         uint256 requestedAmount
/*LN-50*/     ) external returns (uint256) {
/*LN-51*/         uint256 userBalance = supplied[msg.sender][asset];
/*LN-52*/         require(userBalance > 0, "No balance");
/*LN-53*/ 
/*LN-54*/         uint256 withdrawAmount = requestedAmount;
/*LN-55*/         if (requestedAmount == type(uint256).max) {
/*LN-56*/             withdrawAmount = userBalance;
/*LN-57*/         }
/*LN-58*/         require(withdrawAmount <= userBalance, "Insufficient balance");
/*LN-59*/ 
/*LN-60*/         IERC777(asset).transfer(msg.sender, withdrawAmount);
/*LN-61*/ 
/*LN-62*/         supplied[msg.sender][asset] -= withdrawAmount;
/*LN-63*/         totalSupplied[asset] -= withdrawAmount;
/*LN-64*/ 
/*LN-65*/         userWithdrawCount[msg.sender] += 1;
/*LN-66*/         _recordActivity(msg.sender, withdrawAmount);
/*LN-67*/ 
/*LN-68*/         return withdrawAmount;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function getSupplied(
/*LN-72*/         address user,
/*LN-73*/         address asset
/*LN-74*/     ) external view returns (uint256) {
/*LN-75*/         return supplied[user][asset];
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     // Configuration-like helper
/*LN-79*/     function setPoolConfigVersion(uint256 version) external {
/*LN-80*/         poolConfigVersion = version;
/*LN-81*/         lastConfigUpdate = block.timestamp;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     // Internal analytics
/*LN-85*/     function _recordActivity(address user, uint256 value) internal {
/*LN-86*/         if (value > 0) {
/*LN-87*/             uint256 incr = value;
/*LN-88*/             if (incr > 1e24) {
/*LN-89*/                 incr = 1e24;
/*LN-90*/             }
/*LN-91*/ 
/*LN-92*/             userActivityScore[user] = _updateScore(
/*LN-93*/                 userActivityScore[user],
/*LN-94*/                 incr
/*LN-95*/             );
/*LN-96*/             globalActivityScore = _updateScore(globalActivityScore, incr);
/*LN-97*/         }
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function _updateScore(
/*LN-101*/         uint256 current,
/*LN-102*/         uint256 value
/*LN-103*/     ) internal pure returns (uint256) {
/*LN-104*/         uint256 updated;
/*LN-105*/         if (current == 0) {
/*LN-106*/             updated = value;
/*LN-107*/         } else {
/*LN-108*/             updated = (current * 9 + value) / 10;
/*LN-109*/         }
/*LN-110*/ 
/*LN-111*/         if (updated > 1e27) {
/*LN-112*/             updated = 1e27;
/*LN-113*/         }
/*LN-114*/ 
/*LN-115*/         return updated;
/*LN-116*/     }
/*LN-117*/ 
/*LN-118*/     // View helpers
/*LN-119*/     function getUserMetrics(
/*LN-120*/         address user
/*LN-121*/     ) external view returns (uint256 suppliedTotal, uint256 activityScore, uint256 withdraws) {
/*LN-122*/         // Aggregate across assets is not stored; this returns ERC777-based activity information
/*LN-123*/         suppliedTotal = 0;
/*LN-124*/         activityScore = userActivityScore[user];
/*LN-125*/         withdraws = userWithdrawCount[user];
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     function getPoolMetrics()
/*LN-129*/         external
/*LN-130*/         view
/*LN-131*/         returns (uint256 configVersion, uint256 lastUpdate, uint256 activity)
/*LN-132*/     {
/*LN-133*/         configVersion = poolConfigVersion;
/*LN-134*/         lastUpdate = lastConfigUpdate;
/*LN-135*/         activity = globalActivityScore;
/*LN-136*/     }
/*LN-137*/ }
/*LN-138*/ 