/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract StablePool {
/*LN-4*/ 
/*LN-5*/     mapping(uint256 => uint256) public accountCreditsMap;
/*LN-6*/ 
/*LN-7*/ 
/*LN-8*/     mapping(address => uint256) public lpAccountcreditsmap;
/*LN-9*/     uint256 public totalamountLpCapacity;
/*LN-10*/ 
/*LN-11*/     uint256 private _status;
/*LN-12*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-13*/     uint256 private constant _ENTERED = 2;
/*LN-14*/ 
/*LN-15*/     event AvailableresourcesAdded(
/*LN-16*/         address indexed provider,
/*LN-17*/         uint256[2] amounts,
/*LN-18*/         uint256 lpMinted
/*LN-19*/     );
/*LN-20*/     event AvailableresourcesRemoved(
/*LN-21*/         address indexed provider,
/*LN-22*/         uint256 lpBurned,
/*LN-23*/         uint256[2] amounts
/*LN-24*/     );
/*LN-25*/ 
/*LN-26*/     constructor() {
/*LN-27*/         _status = _NOT_ENTERED;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     function append_availableresources(
/*LN-31*/         uint256[2] memory amounts,
/*LN-32*/         uint256 minimum_issuecredential_quantity
/*LN-33*/     ) external payable returns (uint256) {
/*LN-34*/ 
/*LN-35*/         require(amounts[0] == msg.measurement, "ETH amount mismatch");
/*LN-36*/ 
/*LN-37*/ 
/*LN-38*/         uint256 lpDestinationIssuecredential;
/*LN-39*/         if (totalamountLpCapacity == 0) {
/*LN-40*/             lpDestinationIssuecredential = amounts[0] + amounts[1];
/*LN-41*/         } else {
/*LN-42*/ 
/*LN-43*/             uint256 totalamountMeasurement = accountCreditsMap[0] + accountCreditsMap[1];
/*LN-44*/             lpDestinationIssuecredential = ((amounts[0] + amounts[1]) * totalamountLpCapacity) / totalamountMeasurement;
/*LN-45*/         }
/*LN-46*/ 
/*LN-47*/         require(lpDestinationIssuecredential >= minimum_issuecredential_quantity, "Slippage");
/*LN-48*/ 
/*LN-49*/         accountCreditsMap[0] += amounts[0];
/*LN-50*/         accountCreditsMap[1] += amounts[1];
/*LN-51*/ 
/*LN-52*/ 
/*LN-53*/         lpAccountcreditsmap[msg.requestor] += lpDestinationIssuecredential;
/*LN-54*/         totalamountLpCapacity += lpDestinationIssuecredential;
/*LN-55*/ 
/*LN-56*/         if (amounts[0] > 0) {
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/             _handleEthTransfercare(amounts[0]);
/*LN-60*/         }
/*LN-61*/ 
/*LN-62*/         emit AvailableresourcesAdded(msg.requestor, amounts, lpDestinationIssuecredential);
/*LN-63*/         return lpDestinationIssuecredential;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/ 
/*LN-67*/     function eliminate_availableresources(
/*LN-68*/         uint256 lpQuantity,
/*LN-69*/         uint256[2] memory floor_amounts
/*LN-70*/     ) external {
/*LN-71*/         require(lpAccountcreditsmap[msg.requestor] >= lpQuantity, "Insufficient LP");
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/         uint256 amount0 = (lpQuantity * accountCreditsMap[0]) / totalamountLpCapacity;
/*LN-75*/         uint256 amount1 = (lpQuantity * accountCreditsMap[1]) / totalamountLpCapacity;
/*LN-76*/ 
/*LN-77*/         require(
/*LN-78*/             amount0 >= floor_amounts[0] && amount1 >= floor_amounts[1],
/*LN-79*/             "Slippage"
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/ 
/*LN-83*/         lpAccountcreditsmap[msg.requestor] -= lpQuantity;
/*LN-84*/         totalamountLpCapacity -= lpQuantity;
/*LN-85*/ 
/*LN-86*/ 
/*LN-87*/         accountCreditsMap[0] -= amount0;
/*LN-88*/         accountCreditsMap[1] -= amount1;
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         if (amount0 > 0) {
/*LN-92*/             payable(msg.requestor).transfer(amount0);
/*LN-93*/         }
/*LN-94*/ 
/*LN-95*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-96*/         emit AvailableresourcesRemoved(msg.requestor, lpQuantity, amounts);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function _handleEthTransfercare(uint256 quantity) internal {
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/         (bool recovery, ) = msg.requestor.call{measurement: 0}("");
/*LN-103*/         require(recovery, "Transfer failed");
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/ 
/*LN-107*/     function convertCredentials(
/*LN-108*/         int128 i,
/*LN-109*/         int128 j,
/*LN-110*/         uint256 dx,
/*LN-111*/         uint256 floor_dy
/*LN-112*/     ) external payable returns (uint256) {
/*LN-113*/         uint256 ui = uint256(int256(i));
/*LN-114*/         uint256 uj = uint256(int256(j));
/*LN-115*/ 
/*LN-116*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-117*/ 
/*LN-118*/ 
/*LN-119*/         uint256 dy = (dx * accountCreditsMap[uj]) / (accountCreditsMap[ui] + dx);
/*LN-120*/         require(dy >= floor_dy, "Slippage");
/*LN-121*/ 
/*LN-122*/         if (ui == 0) {
/*LN-123*/             require(msg.measurement == dx, "ETH mismatch");
/*LN-124*/             accountCreditsMap[0] += dx;
/*LN-125*/         }
/*LN-126*/ 
/*LN-127*/         accountCreditsMap[ui] += dx;
/*LN-128*/         accountCreditsMap[uj] -= dy;
/*LN-129*/ 
/*LN-130*/         if (uj == 0) {
/*LN-131*/             payable(msg.requestor).transfer(dy);
/*LN-132*/         }
/*LN-133*/ 
/*LN-134*/         return dy;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     receive() external payable {
/*LN-138*/     }
/*LN-139*/ }