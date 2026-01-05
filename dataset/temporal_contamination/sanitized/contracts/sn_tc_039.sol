/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ enum TokenLockup {
/*LN-19*/     Unlocked,
/*LN-20*/     Locked,
/*LN-21*/     Vesting
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ struct Campaign {
/*LN-25*/     address manager;
/*LN-26*/     address token;
/*LN-27*/     uint256 amount;
/*LN-28*/     uint256 end;
/*LN-29*/     TokenLockup tokenLockup;
/*LN-30*/     bytes32 root;
/*LN-31*/ }
/*LN-32*/ 
/*LN-33*/ struct ClaimLockup {
/*LN-34*/     address tokenLocker;
/*LN-35*/     uint256 start;
/*LN-36*/     uint256 cliff;
/*LN-37*/     uint256 period;
/*LN-38*/     uint256 periods;
/*LN-39*/ }
/*LN-40*/ 
/*LN-41*/ struct Donation {
/*LN-42*/     address tokenLocker;
/*LN-43*/     uint256 amount;
/*LN-44*/     uint256 rate;
/*LN-45*/     uint256 start;
/*LN-46*/     uint256 cliff;
/*LN-47*/     uint256 period;
/*LN-48*/ }
/*LN-49*/ 
/*LN-50*/ contract TokenClaimCampaigns {
/*LN-51*/     mapping(bytes16 => Campaign) public campaigns;
/*LN-52*/ 
/*LN-53*/     function createLockedCampaign(
/*LN-54*/         bytes16 id,
/*LN-55*/         Campaign memory campaign,
/*LN-56*/         ClaimLockup memory claimLockup,
/*LN-57*/         Donation memory donation
/*LN-58*/     ) external {
/*LN-59*/         require(campaigns[id].manager == address(0), "Campaign exists");
/*LN-60*/ 
/*LN-61*/         campaigns[id] = campaign;
/*LN-62*/ 
/*LN-63*/         if (donation.amount > 0 && donation.tokenLocker != address(0)) {
/*LN-64*/ 
/*LN-65*/             (bool success, ) = donation.tokenLocker.call(
/*LN-66*/                 abi.encodeWithSignature(
/*LN-67*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-68*/                     campaign.token,
/*LN-69*/                     donation.amount,
/*LN-70*/                     donation.start,
/*LN-71*/                     donation.cliff,
/*LN-72*/                     donation.rate,
/*LN-73*/                     donation.period
/*LN-74*/                 )
/*LN-75*/             );
/*LN-76*/ 
/*LN-77*/             require(success, "Token lock failed");
/*LN-78*/         }
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     /**
/*LN-82*/      * @notice Cancel a campaign
/*LN-83*/      */
/*LN-84*/     function cancelCampaign(bytes16 campaignId) external {
/*LN-85*/         require(campaigns[campaignId].manager == msg.sender, "Not manager");
/*LN-86*/         delete campaigns[campaignId];
/*LN-87*/     }
/*LN-88*/ }
/*LN-89*/ 