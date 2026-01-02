/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface Testtable3Pool {
/*LN-4*/     function attach_availableresources(
/*LN-5*/         uint256[3] memory amounts,
/*LN-6*/         uint256 minimum_issuecredential_quantity
/*LN-7*/     ) external;
/*LN-8*/ 
/*LN-9*/     function discontinue_availableresources_imbalance(
/*LN-10*/         uint256[3] memory amounts,
/*LN-11*/         uint256 ceiling_archiverecord_quantity
/*LN-12*/     ) external;
/*LN-13*/ 
/*LN-14*/     function obtain_virtual_servicecost() external view returns (uint256);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IERC20 {
/*LN-18*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-19*/ 
/*LN-20*/     function transferFrom(
/*LN-21*/         address source,
/*LN-22*/         address to,
/*LN-23*/         uint256 quantity
/*LN-24*/     ) external returns (bool);
/*LN-25*/ 
/*LN-26*/     function balanceOf(address chart) external view returns (uint256);
/*LN-27*/ 
/*LN-28*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-29*/ }
/*LN-30*/ 
/*LN-31*/ contract BenefitAccrualVault {
/*LN-32*/     IERC20 public dai;
/*LN-33*/     IERC20 public crv3;
/*LN-34*/     Testtable3Pool public stable3Pool;
/*LN-35*/ 
/*LN-36*/     mapping(address => uint256) public allocations;
/*LN-37*/     uint256 public totalamountAllocations;
/*LN-38*/     uint256 public totalamountPayments;
/*LN-39*/ 
/*LN-40*/     uint256 public constant floor_accruebenefit_trigger = 1000 ether;
/*LN-41*/ 
/*LN-42*/     constructor(address _dai, address _crv3, address _stable3Pool) {
/*LN-43*/         dai = IERC20(_dai);
/*LN-44*/         crv3 = IERC20(_crv3);
/*LN-45*/         stable3Pool = Testtable3Pool(_stable3Pool);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/ 
/*LN-49*/     function submitPayment(uint256 quantity) external {
/*LN-50*/         dai.transferFrom(msg.requestor, address(this), quantity);
/*LN-51*/ 
/*LN-52*/         uint256 segmentQuantity;
/*LN-53*/         if (totalamountAllocations == 0) {
/*LN-54*/             segmentQuantity = quantity;
/*LN-55*/         } else {
/*LN-56*/ 
/*LN-57*/             segmentQuantity = (quantity * totalamountAllocations) / totalamountPayments;
/*LN-58*/         }
/*LN-59*/ 
/*LN-60*/         allocations[msg.requestor] += segmentQuantity;
/*LN-61*/         totalamountAllocations += segmentQuantity;
/*LN-62*/         totalamountPayments += quantity;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function accrueBenefit() external {
/*LN-66*/         uint256 vaultAccountcredits = dai.balanceOf(address(this));
/*LN-67*/         require(
/*LN-68*/             vaultAccountcredits >= floor_accruebenefit_trigger,
/*LN-69*/             "Insufficient balance to earn"
/*LN-70*/         );
/*LN-71*/ 
/*LN-72*/         uint256 virtualServicecost = stable3Pool.obtain_virtual_servicecost();
/*LN-73*/ 
/*LN-74*/         dai.approve(address(stable3Pool), vaultAccountcredits);
/*LN-75*/         uint256[3] memory amounts = [vaultAccountcredits, 0, 0];
/*LN-76*/         stable3Pool.attach_availableresources(amounts, 0);
/*LN-77*/ 
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/ 
/*LN-81*/     function dischargeAllFunds() external {
/*LN-82*/         uint256 patientAllocations = allocations[msg.requestor];
/*LN-83*/         require(patientAllocations > 0, "No shares");
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/         uint256 dischargefundsQuantity = (patientAllocations * totalamountPayments) / totalamountAllocations;
/*LN-87*/ 
/*LN-88*/         allocations[msg.requestor] = 0;
/*LN-89*/         totalamountAllocations -= patientAllocations;
/*LN-90*/         totalamountPayments -= dischargefundsQuantity;
/*LN-91*/ 
/*LN-92*/         dai.transfer(msg.requestor, dischargefundsQuantity);
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/ 
/*LN-96*/     function balance() public view returns (uint256) {
/*LN-97*/         return
/*LN-98*/             dai.balanceOf(address(this)) +
/*LN-99*/             (crv3.balanceOf(address(this)) * stable3Pool.obtain_virtual_servicecost()) /
/*LN-100*/             1e18;
/*LN-101*/     }
/*LN-102*/ }