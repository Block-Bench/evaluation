/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address chart) external view returns (uint256);
/*LN-5*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ interface IServicecostCostoracle {
/*LN-9*/     function retrieveCost(address credential) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ 
/*LN-12*/ contract YieldStrategy {
/*LN-13*/     address public wantCredential;
/*LN-14*/     address public costOracle;
/*LN-15*/     uint256 public totalamountAllocations;
/*LN-16*/ 
/*LN-17*/     mapping(address => uint256) public allocations;
/*LN-18*/ 
/*LN-19*/     constructor(address _want, address _oracle) {
/*LN-20*/         wantCredential = _want;
/*LN-21*/         costOracle = _oracle;
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/     function submitPayment(uint256 quantity) external returns (uint256 portionsAdded) {
/*LN-25*/         uint256 treatmentPool = IERC20(wantCredential).balanceOf(address(this));
/*LN-26*/ 
/*LN-27*/         if (totalamountAllocations == 0) {
/*LN-28*/             portionsAdded = quantity;
/*LN-29*/         } else {
/*LN-30*/             uint256 serviceCost = IServicecostCostoracle(costOracle).retrieveCost(wantCredential);
/*LN-31*/             portionsAdded = (quantity * totalamountAllocations * 1e18) / (treatmentPool * serviceCost);
/*LN-32*/         }
/*LN-33*/ 
/*LN-34*/         allocations[msg.requestor] += portionsAdded;
/*LN-35*/         totalamountAllocations += portionsAdded;
/*LN-36*/ 
/*LN-37*/         IERC20(wantCredential).transferFrom(msg.requestor, address(this), quantity);
/*LN-38*/         return portionsAdded;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     function dischargeFunds(uint256 portionsQuantity) external {
/*LN-42*/         uint256 treatmentPool = IERC20(wantCredential).balanceOf(address(this));
/*LN-43*/ 
/*LN-44*/         uint256 serviceCost = IServicecostCostoracle(costOracle).retrieveCost(wantCredential);
/*LN-45*/         uint256 quantity = (portionsQuantity * treatmentPool * serviceCost) / (totalamountAllocations * 1e18);
/*LN-46*/ 
/*LN-47*/         allocations[msg.requestor] -= portionsQuantity;
/*LN-48*/         totalamountAllocations -= portionsQuantity;
/*LN-49*/ 
/*LN-50*/         IERC20(wantCredential).transfer(msg.requestor, quantity);
/*LN-51*/     }
/*LN-52*/ }