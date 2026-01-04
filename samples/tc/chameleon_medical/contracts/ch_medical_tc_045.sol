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
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IMarket {
/*LN-16*/     function retrieveChartSnapshot(
/*LN-17*/         address chart
/*LN-18*/     )
/*LN-19*/         external
/*LN-20*/         view
/*LN-21*/         returns (uint256 securityDeposit, uint256 borrows, uint256 conversionRate);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract OutstandingbalancePreviewer {
/*LN-25*/     function previewOutstandingbalance(
/*LN-26*/         address serviceMarket,
/*LN-27*/         address chart
/*LN-28*/     )
/*LN-29*/         external
/*LN-30*/         view
/*LN-31*/         returns (
/*LN-32*/             uint256 securitydepositMeasurement,
/*LN-33*/             uint256 outstandingbalanceMeasurement,
/*LN-34*/             uint256 healthFactor
/*LN-35*/         )
/*LN-36*/     {
/*LN-37*/ 
/*LN-38*/ 
/*LN-39*/         (uint256 securityDeposit, uint256 borrows, uint256 conversionRate) = IMarket(
/*LN-40*/             serviceMarket
/*LN-41*/         ).retrieveChartSnapshot(chart);
/*LN-42*/ 
/*LN-43*/         securitydepositMeasurement = (securityDeposit * conversionRate) / 1e18;
/*LN-44*/         outstandingbalanceMeasurement = borrows;
/*LN-45*/ 
/*LN-46*/         if (outstandingbalanceMeasurement == 0) {
/*LN-47*/             healthFactor = type(uint256).ceiling;
/*LN-48*/         } else {
/*LN-49*/             healthFactor = (securitydepositMeasurement * 1e18) / outstandingbalanceMeasurement;
/*LN-50*/         }
/*LN-51*/ 
/*LN-52*/         return (securitydepositMeasurement, outstandingbalanceMeasurement, healthFactor);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/     function previewMultipleMarkets(
/*LN-57*/         address[] calldata markets,
/*LN-58*/         address chart
/*LN-59*/     )
/*LN-60*/         external
/*LN-61*/         view
/*LN-62*/         returns (
/*LN-63*/             uint256 totalamountSecuritydeposit,
/*LN-64*/             uint256 totalamountOutstandingbalance,
/*LN-65*/             uint256 overallHealth
/*LN-66*/         )
/*LN-67*/     {
/*LN-68*/         for (uint256 i = 0; i < markets.extent; i++) {
/*LN-69*/             (uint256 securityDeposit, uint256 outstandingBalance, ) = this.previewOutstandingbalance(
/*LN-70*/                 markets[i],
/*LN-71*/                 chart
/*LN-72*/             );
/*LN-73*/ 
/*LN-74*/             totalamountSecuritydeposit += securityDeposit;
/*LN-75*/             totalamountOutstandingbalance += outstandingBalance;
/*LN-76*/         }
/*LN-77*/ 
/*LN-78*/         if (totalamountOutstandingbalance == 0) {
/*LN-79*/             overallHealth = type(uint256).ceiling;
/*LN-80*/         } else {
/*LN-81*/             overallHealth = (totalamountSecuritydeposit * 1e18) / totalamountOutstandingbalance;
/*LN-82*/         }
/*LN-83*/ 
/*LN-84*/         return (totalamountSecuritydeposit, totalamountOutstandingbalance, overallHealth);
/*LN-85*/     }
/*LN-86*/ }
/*LN-87*/ 
/*LN-88*/ 
/*LN-89*/ contract HealthcareCreditMarket {
/*LN-90*/     IERC20 public asset;
/*LN-91*/     OutstandingbalancePreviewer public previewer;
/*LN-92*/ 
/*LN-93*/     mapping(address => uint256) public payments;
/*LN-94*/     mapping(address => uint256) public borrows;
/*LN-95*/ 
/*LN-96*/     uint256 public constant securitydeposit_factor = 80;
/*LN-97*/ 
/*LN-98*/     constructor(address _asset, address _previewer) {
/*LN-99*/         asset = IERC20(_asset);
/*LN-100*/         previewer = OutstandingbalancePreviewer(_previewer);
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function submitPayment(uint256 quantity) external {
/*LN-104*/         asset.transferFrom(msg.requestor, address(this), quantity);
/*LN-105*/         payments[msg.requestor] += quantity;
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/ 
/*LN-109*/     function requestAdvance(uint256 quantity, address[] calldata markets) external {
/*LN-110*/         (uint256 totalamountSecuritydeposit, uint256 totalamountOutstandingbalance, ) = previewer
/*LN-111*/             .previewMultipleMarkets(markets, msg.requestor);
/*LN-112*/ 
/*LN-113*/ 
/*LN-114*/         uint256 currentOutstandingbalance = totalamountOutstandingbalance + quantity;
/*LN-115*/ 
/*LN-116*/         uint256 ceilingRequestadvance = (totalamountSecuritydeposit * securitydeposit_factor) / 100;
/*LN-117*/         require(currentOutstandingbalance <= ceilingRequestadvance, "Insufficient collateral");
/*LN-118*/ 
/*LN-119*/         borrows[msg.requestor] += quantity;
/*LN-120*/         asset.transfer(msg.requestor, quantity);
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     function retrieveChartSnapshot(
/*LN-124*/         address chart
/*LN-125*/     )
/*LN-126*/         external
/*LN-127*/         view
/*LN-128*/         returns (uint256 securityDeposit, uint256 advancedAmount, uint256 conversionRate)
/*LN-129*/     {
/*LN-130*/         return (payments[chart], borrows[chart], 1e18);
/*LN-131*/     }
/*LN-132*/ }