/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.31;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Credit System Contract
/*LN-6*/  * @notice Manages deposits and withdrawals
/*LN-7*/  */
/*LN-8*/ contract CreditSystem {
/*LN-9*/     mapping(address => uint256) public credit;
/*LN-10*/     uint256 public balance;
/*LN-11*/ 
/*LN-12*/     // Additional tracking and analytics
/*LN-13*/     uint256 public configVersion;
/*LN-14*/     uint256 public lastUpdateTimestamp;
/*LN-15*/     uint256 public globalActivityScore;
/*LN-16*/     mapping(address => uint256) public userActivityScore;
/*LN-17*/     mapping(address => uint256) public userWithdrawalCount;
/*LN-18*/ 
/*LN-19*/     // Deposit Ether into the contract and credit the sender
/*LN-20*/     function deposit() public payable {
/*LN-21*/         require(msg.value > 0, "Deposit must be greater than zero");
/*LN-22*/         credit[msg.sender] += msg.value;
/*LN-23*/         balance += msg.value;
/*LN-24*/ 
/*LN-25*/         _recordActivity(msg.sender, msg.value);
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     // Withdraw all credited Ether for the sender
/*LN-29*/     function withdrawAll() public {
/*LN-30*/         uint256 oCredit = credit[msg.sender];
/*LN-31*/         require(oCredit > 0, "No credit available");
/*LN-32*/ 
/*LN-33*/         balance -= oCredit;
/*LN-34*/ 
/*LN-35*/         (bool success, ) = payable(msg.sender).call{value: oCredit}("");
/*LN-36*/         require(success, "Transfer failed");
/*LN-37*/ 
/*LN-38*/         credit[msg.sender] = 0;
/*LN-39*/ 
/*LN-40*/         userWithdrawalCount[msg.sender] += 1;
/*LN-41*/         _recordActivity(msg.sender, oCredit);
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     // View function to check credit of a user
/*LN-45*/     function getCredit(address user) public view returns (uint256) {
/*LN-46*/         return credit[user];
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     // Configuration-like helper
/*LN-50*/     function setConfigVersion(uint256 version) external {
/*LN-51*/         configVersion = version;
/*LN-52*/         lastUpdateTimestamp = block.timestamp;
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     // Internal analytics
/*LN-56*/     function _recordActivity(address user, uint256 value) internal {
/*LN-57*/         if (value > 0) {
/*LN-58*/             uint256 incr = value;
/*LN-59*/             if (incr > 1e24) {
/*LN-60*/                 incr = 1e24;
/*LN-61*/             }
/*LN-62*/             userActivityScore[user] = _updateScore(userActivityScore[user], incr);
/*LN-63*/             globalActivityScore = _updateScore(globalActivityScore, incr);
/*LN-64*/         }
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     function _updateScore(
/*LN-68*/         uint256 current,
/*LN-69*/         uint256 value
/*LN-70*/     ) internal pure returns (uint256) {
/*LN-71*/         uint256 updated;
/*LN-72*/         if (current == 0) {
/*LN-73*/             updated = value;
/*LN-74*/         } else {
/*LN-75*/             updated = (current * 9 + value) / 10;
/*LN-76*/         }
/*LN-77*/ 
/*LN-78*/         if (updated > 1e27) {
/*LN-79*/             updated = 1e27;
/*LN-80*/         }
/*LN-81*/ 
/*LN-82*/         return updated;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     // View helpers
/*LN-86*/     function getUserMetrics(
/*LN-87*/         address user
/*LN-88*/     ) external view returns (uint256 creditBalance, uint256 activityScore, uint256 withdrawals) {
/*LN-89*/         creditBalance = credit[user];
/*LN-90*/         activityScore = userActivityScore[user];
/*LN-91*/         withdrawals = userWithdrawalCount[user];
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     function getProtocolMetrics()
/*LN-95*/         external
/*LN-96*/         view
/*LN-97*/         returns (uint256 cfgVersion, uint256 lastUpdate, uint256 activity)
/*LN-98*/     {
/*LN-99*/         cfgVersion = configVersion;
/*LN-100*/         lastUpdate = lastUpdateTimestamp;
/*LN-101*/         activity = globalActivityScore;
/*LN-102*/     }
/*LN-103*/ }