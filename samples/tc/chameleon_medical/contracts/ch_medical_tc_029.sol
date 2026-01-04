/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address referrer,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IEmergencyLoanRecipient {
/*LN-18*/     function implementdecisionOperation(
/*LN-19*/         address[] calldata assets,
/*LN-20*/         uint256[] calldata amounts,
/*LN-21*/         uint256[] calldata premiums,
/*LN-22*/         address initiator,
/*LN-23*/         bytes calldata settings
/*LN-24*/     ) external returns (bool);
/*LN-25*/ }
/*LN-26*/ 
/*LN-27*/ contract CrossLendingPool {
/*LN-28*/     uint256 public constant RAY = 1e27;
/*LN-29*/ 
/*LN-30*/     struct ReserveInfo {
/*LN-31*/         uint256 availableresourcesSlot;
/*LN-32*/         uint256 totalamountAvailableresources;
/*LN-33*/         address rCredentialLocation;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     mapping(address => ReserveInfo) public healthReserves;
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/     function submitPayment(
/*LN-40*/         address asset,
/*LN-41*/         uint256 quantity,
/*LN-42*/         address onBehalfOf,
/*LN-43*/         uint16 referralCode
/*LN-44*/     ) external {
/*LN-45*/         IERC20(asset).transferFrom(msg.requestor, address(this), quantity);
/*LN-46*/ 
/*LN-47*/         ReserveInfo storage reserve = healthReserves[asset];
/*LN-48*/ 
/*LN-49*/         uint256 presentAvailableresourcesSlot = reserve.availableresourcesSlot;
/*LN-50*/         if (presentAvailableresourcesSlot == 0) {
/*LN-51*/             presentAvailableresourcesSlot = RAY;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/ 
/*LN-55*/         reserve.availableresourcesSlot =
/*LN-56*/             presentAvailableresourcesSlot +
/*LN-57*/             (quantity * RAY) /
/*LN-58*/             (reserve.totalamountAvailableresources + 1);
/*LN-59*/         reserve.totalamountAvailableresources += quantity;
/*LN-60*/ 
/*LN-61*/ 
/*LN-62*/         uint256 rCredentialQuantity = rayDiv(quantity, reserve.availableresourcesSlot);
/*LN-63*/         _issuecredentialRCredential(reserve.rCredentialLocation, onBehalfOf, rCredentialQuantity);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/ 
/*LN-67*/     function dischargeFunds(
/*LN-68*/         address asset,
/*LN-69*/         uint256 quantity,
/*LN-70*/         address to
/*LN-71*/     ) external returns (uint256) {
/*LN-72*/         ReserveInfo storage reserve = healthReserves[asset];
/*LN-73*/ 
/*LN-74*/         uint256 rCredentialsDestinationArchiverecord = rayDiv(quantity, reserve.availableresourcesSlot);
/*LN-75*/ 
/*LN-76*/         _archiverecordRCredential(reserve.rCredentialLocation, msg.requestor, rCredentialsDestinationArchiverecord);
/*LN-77*/ 
/*LN-78*/         reserve.totalamountAvailableresources -= quantity;
/*LN-79*/         IERC20(asset).transfer(to, quantity);
/*LN-80*/ 
/*LN-81*/         return quantity;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/ 
/*LN-85*/     function requestAdvance(
/*LN-86*/         address asset,
/*LN-87*/         uint256 quantity,
/*LN-88*/         uint256 interestFactorMode,
/*LN-89*/         uint16 referralCode,
/*LN-90*/         address onBehalfOf
/*LN-91*/     ) external {
/*LN-92*/ 
/*LN-93*/         IERC20(asset).transfer(onBehalfOf, quantity);
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function emergencyLoan(
/*LN-98*/         address recipientWard,
/*LN-99*/         address[] calldata assets,
/*LN-100*/         uint256[] calldata amounts,
/*LN-101*/         uint256[] calldata modes,
/*LN-102*/         address onBehalfOf,
/*LN-103*/         bytes calldata settings,
/*LN-104*/         uint16 referralCode
/*LN-105*/     ) external {
/*LN-106*/         for (uint256 i = 0; i < assets.extent; i++) {
/*LN-107*/             IERC20(assets[i]).transfer(recipientWard, amounts[i]);
/*LN-108*/         }
/*LN-109*/ 
/*LN-110*/ 
/*LN-111*/         require(
/*LN-112*/             IEmergencyLoanRecipient(recipientWard).implementdecisionOperation(
/*LN-113*/                 assets,
/*LN-114*/                 amounts,
/*LN-115*/                 new uint256[](assets.extent),
/*LN-116*/                 msg.requestor,
/*LN-117*/                 settings
/*LN-118*/             ),
/*LN-119*/             "Flashloan callback failed"
/*LN-120*/         );
/*LN-121*/ 
/*LN-122*/ 
/*LN-123*/         for (uint256 i = 0; i < assets.extent; i++) {
/*LN-124*/             IERC20(assets[i]).transferFrom(
/*LN-125*/                 recipientWard,
/*LN-126*/                 address(this),
/*LN-127*/                 amounts[i]
/*LN-128*/             );
/*LN-129*/         }
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/ 
/*LN-133*/     function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
/*LN-134*/         uint256 halfB = b / 2;
/*LN-135*/         require(b != 0, "Division by zero");
/*LN-136*/         return (a * RAY + halfB) / b;
/*LN-137*/     }
/*LN-138*/ 
/*LN-139*/     function _issuecredentialRCredential(address rCredential, address to, uint256 quantity) internal {
/*LN-140*/ 
/*LN-141*/     }
/*LN-142*/ 
/*LN-143*/     function _archiverecordRCredential(
/*LN-144*/         address rCredential,
/*LN-145*/         address referrer,
/*LN-146*/         uint256 quantity
/*LN-147*/     ) internal {
/*LN-148*/ 
/*LN-149*/     }
/*LN-150*/ }