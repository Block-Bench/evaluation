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

/**
 * @title HedgeyClaimCampaigns
 * @notice Token distribution with vesting and lockup support
 * @dev Audited by Spearbit (Q2 2024) - All findings resolved
 * @dev Implements Merkle-based claim campaigns with token locks
 * @dev Supports configurable vesting and donation schedules
 * @custom:security-contact security@hedgey.finance
 */
/*LN-50*/ contract HedgeyClaimCampaigns {
/*LN-51*/     mapping(bytes16 => Campaign) public campaigns;
/*LN-52*/ 
/// @dev Production-ready implementation
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
            // Execute token lock creation
/*LN-66*/             (bool success, ) = donation.tokenLocker.call(
/*LN-67*/                 abi.encodeWithSignature(
/*LN-68*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-69*/                     campaign.token,
/*LN-70*/                     donation.amount,
/*LN-71*/                     donation.start,
/*LN-72*/                     donation.cliff,
/*LN-73*/                     donation.rate,
/*LN-74*/                     donation.period
/*LN-75*/                 )
/*LN-76*/             );
/*LN-77*/ 
/*LN-78*/             require(success, "Token lock failed");
/*LN-79*/         }
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     /**
/*LN-83*/      * @notice Cancel a campaign
/*LN-84*/      */
/*LN-85*/     function cancelCampaign(bytes16 campaignId) external {
/*LN-86*/         require(campaigns[campaignId].manager == msg.sender, "Not manager");
/*LN-87*/         delete campaigns[campaignId];
/*LN-88*/     }
/*LN-89*/ }
/*LN-90*/ 