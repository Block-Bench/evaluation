/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ enum TokenLockup {
/*LN-16*/     Unlocked,
/*LN-17*/     Locked,
/*LN-18*/     Vesting
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ struct Campaign {
/*LN-22*/     address manager;
/*LN-23*/     address token;
/*LN-24*/     uint256 amount;
/*LN-25*/     uint256 end;
/*LN-26*/     TokenLockup tokenLockup;
/*LN-27*/     bytes32 root;
/*LN-28*/ }
/*LN-29*/ 
/*LN-30*/ struct ClaimLockup {
/*LN-31*/     address tokenLocker;
/*LN-32*/     uint256 start;
/*LN-33*/     uint256 cliff;
/*LN-34*/     uint256 period;
/*LN-35*/     uint256 periods;
/*LN-36*/ }
/*LN-37*/ 
/*LN-38*/ struct Donation {
/*LN-39*/     address tokenLocker;
/*LN-40*/     uint256 amount;
/*LN-41*/     uint256 rate;
/*LN-42*/     uint256 start;
/*LN-43*/     uint256 cliff;
/*LN-44*/     uint256 period;
/*LN-45*/ }
/*LN-46*/ 
/*LN-47*/ contract HedgeyClaimCampaigns {
/*LN-48*/     mapping(bytes16 => Campaign) public campaigns;
/*LN-49*/     mapping(address => bool) public approvedTokenLockers;
/*LN-50*/     address public admin;
/*LN-51*/ 
/*LN-52*/     constructor() {
/*LN-53*/         admin = msg.sender;
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     modifier onlyAdmin() {
/*LN-57*/         require(msg.sender == admin, "Not admin");
/*LN-58*/         _;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function addApprovedTokenLocker(address locker) external onlyAdmin {
/*LN-62*/         approvedTokenLockers[locker] = true;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function createLockedCampaign(
/*LN-66*/         bytes16 id,
/*LN-67*/         Campaign memory campaign,
/*LN-68*/         ClaimLockup memory claimLockup,
/*LN-69*/         Donation memory donation
/*LN-70*/     ) external {
/*LN-71*/         require(campaigns[id].manager == address(0), "Campaign exists");
/*LN-72*/         require(approvedTokenLockers[donation.tokenLocker], "TokenLocker not approved");
/*LN-73*/ 
/*LN-74*/         campaigns[id] = campaign;
/*LN-75*/ 
/*LN-76*/         if (donation.amount > 0 && donation.tokenLocker != address(0)) {
/*LN-77*/             (bool success, ) = donation.tokenLocker.call(
/*LN-78*/                 abi.encodeWithSignature(
/*LN-79*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-80*/                     campaign.token,
/*LN-81*/                     donation.amount,
/*LN-82*/                     donation.start,
/*LN-83*/                     donation.cliff,
/*LN-84*/                     donation.rate,
/*LN-85*/                     donation.period
/*LN-86*/                 )
/*LN-87*/             );
/*LN-88*/ 
/*LN-89*/             require(success, "Token lock failed");
/*LN-90*/         }
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     function cancelCampaign(bytes16 campaignId) external {
/*LN-94*/         require(campaigns[campaignId].manager == msg.sender, "Not manager");
/*LN-95*/         delete campaigns[campaignId];
/*LN-96*/     }
/*LN-97*/ }
/*LN-98*/ 