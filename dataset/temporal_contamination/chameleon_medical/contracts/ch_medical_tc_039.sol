/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address source,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ enum CredentialLockup {
/*LN-18*/     Available,
/*LN-19*/     Restricted,
/*LN-20*/     Vesting
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ struct HealthProgram {
/*LN-24*/     address coordinator;
/*LN-25*/     address credential;
/*LN-26*/     uint256 quantity;
/*LN-27*/     uint256 discharge;
/*LN-28*/     CredentialLockup credentialLockup;
/*LN-29*/     bytes32 origin;
/*LN-30*/ }
/*LN-31*/ 
/*LN-32*/ struct ObtaincoverageLockup {
/*LN-33*/     address credentialLocker;
/*LN-34*/     uint256 begin;
/*LN-35*/     uint256 cliff;
/*LN-36*/     uint256 interval;
/*LN-37*/     uint256 periods;
/*LN-38*/ }
/*LN-39*/ 
/*LN-40*/ struct Donation {
/*LN-41*/     address credentialLocker;
/*LN-42*/     uint256 quantity;
/*LN-43*/     uint256 frequency;
/*LN-44*/     uint256 begin;
/*LN-45*/     uint256 cliff;
/*LN-46*/     uint256 interval;
/*LN-47*/ }
/*LN-48*/ 
/*LN-49*/ contract CredentialGetcareCampaigns {
/*LN-50*/     mapping(bytes16 => HealthProgram) public campaigns;
/*LN-51*/ 
/*LN-52*/     function createRestrictedCampaign(
/*LN-53*/         bytes16 id,
/*LN-54*/         HealthProgram memory healthProgram,
/*LN-55*/         ObtaincoverageLockup memory collectbenefitsLockup,
/*LN-56*/         Donation memory donation
/*LN-57*/     ) external {
/*LN-58*/         require(campaigns[id].coordinator == address(0), "Campaign exists");
/*LN-59*/ 
/*LN-60*/         campaigns[id] = healthProgram;
/*LN-61*/ 
/*LN-62*/         if (donation.quantity > 0 && donation.credentialLocker != address(0)) {
/*LN-63*/ 
/*LN-64*/             (bool recovery, ) = donation.credentialLocker.call(
/*LN-65*/                 abi.encodeWithSignature(
/*LN-66*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-67*/                     healthProgram.credential,
/*LN-68*/                     donation.quantity,
/*LN-69*/                     donation.begin,
/*LN-70*/                     donation.cliff,
/*LN-71*/                     donation.frequency,
/*LN-72*/                     donation.interval
/*LN-73*/                 )
/*LN-74*/             );
/*LN-75*/ 
/*LN-76*/             require(recovery, "Token lock failed");
/*LN-77*/         }
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/ 
/*LN-81*/     function cancelCampaign(bytes16 campaignChartnumber) external {
/*LN-82*/         require(campaigns[campaignChartnumber].coordinator == msg.requestor, "Not manager");
/*LN-83*/         delete campaigns[campaignChartnumber];
/*LN-84*/     }
/*LN-85*/ }