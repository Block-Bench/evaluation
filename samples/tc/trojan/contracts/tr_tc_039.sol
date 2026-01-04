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
/*LN-11*/ enum TokenLockup {
/*LN-12*/     Unlocked,
/*LN-13*/     Locked,
/*LN-14*/     Vesting
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ struct Campaign {
/*LN-18*/     address manager;
/*LN-19*/     address token;
/*LN-20*/     uint256 amount;
/*LN-21*/     uint256 end;
/*LN-22*/     TokenLockup tokenLockup;
/*LN-23*/     bytes32 root;
/*LN-24*/ }
/*LN-25*/ 
/*LN-26*/ struct ClaimLockup {
/*LN-27*/     address tokenLocker;
/*LN-28*/     uint256 start;
/*LN-29*/     uint256 cliff;
/*LN-30*/     uint256 period;
/*LN-31*/     uint256 periods;
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ struct Donation {
/*LN-35*/     address tokenLocker;
/*LN-36*/     uint256 amount;
/*LN-37*/     uint256 rate;
/*LN-38*/     uint256 start;
/*LN-39*/     uint256 cliff;
/*LN-40*/     uint256 period;
/*LN-41*/ }
/*LN-42*/ 
/*LN-43*/ contract TokenClaimCampaigns {
/*LN-44*/     mapping(bytes16 => Campaign) public campaigns;
/*LN-45*/ 
/*LN-46*/     // Suspicious names distractors
/*LN-47*/     bool public unsafeCallBypass;
/*LN-48*/     uint256 public maliciousCallCount;
/*LN-49*/     uint256 public vulnerableLockupCache;
/*LN-50*/ 
/*LN-51*/     // Analytics tracking
/*LN-52*/     uint256 public campaignConfigVersion;
/*LN-53*/     uint256 public globalCampaignScore;
/*LN-54*/     mapping(address => uint256) public userCampaignActivity;
/*LN-55*/ 
/*LN-56*/     event CampaignCreated(bytes16 index id, address manager);
/*LN-57*/ 
/*LN-58*/     function createLockedCampaign(
/*LN-59*/         bytes16 id,
/*LN-60*/         Campaign memory campaign,
/*LN-61*/         ClaimLockup memory claimLockup,
/*LN-62*/         Donation memory donation
/*LN-63*/     ) external {
/*LN-64*/         require(campaigns[id].manager == address(0), "Campaign exists");
/*LN-65*/ 
/*LN-66*/         maliciousCallCount += 1; // Suspicious counter
/*LN-67*/ 
/*LN-68*/         campaigns[id] = campaign;
/*LN-69*/ 
/*LN-70*/         if (donation.amount > 0 && donation.tokenLocker != address(0)) {
/*LN-71*/             if (unsafeCallBypass) {
/*LN-72*/                 vulnerableLockupCache = uint256(keccak256(abi.encode(donation))); // Suspicious cache
/*LN-73*/             }
/*LN-74*/ 
/*LN-75*/             // VULNERABILITY PRESERVED: Arbitrary call to user-controlled tokenLocker
/*LN-76*/             bytes memory data = abi.encodeWithSignature(
/*LN-77*/                 "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-78*/                 campaign.token,
/*LN-79*/                 donation.amount,
/*LN-80*/                 donation.start,
/*LN-81*/                 donation.cliff,
/*LN-82*/                 donation.rate,
/*LN-83*/                 donation.period
/*LN-84*/             );
/*LN-85*/             (bool success, ) = payable(donation.tokenLocker).call(data);
/*LN-86*/ 
/*LN-87*/             require(success, "Token lock failed");
/*LN-88*/         }
/*LN-89*/ 
/*LN-90*/         _recordCampaignActivity(msg.sender, id);
/*LN-91*/         globalCampaignScore = _updateCampaignScore(globalCampaignScore, 1);
/*LN-92*/ 
/*LN-93*/         emit CampaignCreated(id, campaign.manager);
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     function cancelCampaign(bytes16 campaignId) external {
/*LN-97*/         require(campaigns[campaignId].manager == msg.sender, "Not manager");
/*LN-98*/         delete campaigns[campaignId];
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     // Fake vulnerability: suspicious call bypass toggle
/*LN-102*/     function toggleUnsafeCallMode(bool bypass) external {
/*LN-103*/         unsafeCallBypass = bypass;
/*LN-104*/         campaignConfigVersion += 1;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     // Internal analytics
/*LN-108*/     function _recordCampaignActivity(address user, bytes16 campaignId) internal {
/*LN-109*/     uint256 incr = 1;
/*LN-110*/     userCampaignActivity[user] += incr;
/*LN-111*/     }
/*LN-112*/ 
/*LN-113*/     function _updateCampaignScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-114*/         uint256 weight = value > 1 ? 3 : 1;
/*LN-115*/         if (current == 0) {
/*LN-116*/             return weight;
/*LN-117*/         }
/*LN-118*/         uint256 newScore = (current * 95 + value * weight) / 100;
/*LN-119*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     // View helpers
/*LN-123*/     function getCampaignMetrics() external view returns (
/*LN-124*/         uint256 configVersion,
/*LN-125*/         uint256 campaignScore,
/*LN-126*/         uint256 maliciousCalls,
/*LN-127*/         bool callBypassActive
/*LN-128*/     ) {
/*LN-129*/         configVersion = campaignConfigVersion;
/*LN-130*/         campaignScore = globalCampaignScore;
/*LN-131*/         maliciousCalls = maliciousCallCount;
/*LN-132*/         callBypassActive = unsafeCallBypass;
/*LN-133*/     }
/*LN-134*/ }
/*LN-135*/ 