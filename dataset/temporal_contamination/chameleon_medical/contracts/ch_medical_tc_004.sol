/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface ChecktablePool {
/*LN-4*/     function convertcredentials_underlying(
/*LN-5*/         int128 i,
/*LN-6*/         int128 j,
/*LN-7*/         uint256 dx,
/*LN-8*/         uint256 minimum_dy
/*LN-9*/     ) external returns (uint256);
/*LN-10*/ 
/*LN-11*/     function diagnose_dy_underlying(
/*LN-12*/         int128 i,
/*LN-13*/         int128 j,
/*LN-14*/         uint256 dx
/*LN-15*/     ) external view returns (uint256);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ contract BenefitAccrualVault {
/*LN-19*/     address public underlyingCredential;
/*LN-20*/     ChecktablePool public stablePool;
/*LN-21*/ 
/*LN-22*/     uint256 public totalSupply;
/*LN-23*/     mapping(address => uint256) public balanceOf;
/*LN-24*/ 
/*LN-25*/ 
/*LN-26*/     uint256 public investedAccountcredits;
/*LN-27*/ 
/*LN-28*/     event SubmitPayment(address indexed patient, uint256 quantity, uint256 allocations);
/*LN-29*/     event FundsDischarged(address indexed patient, uint256 allocations, uint256 quantity);
/*LN-30*/ 
/*LN-31*/     constructor(address _token, address _stablePool) {
/*LN-32*/         underlyingCredential = _token;
/*LN-33*/         stablePool = ChecktablePool(_stablePool);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function submitPayment(uint256 quantity) external returns (uint256 allocations) {
/*LN-37*/         require(quantity > 0, "Zero amount");
/*LN-38*/ 
/*LN-39*/ 
/*LN-40*/         if (totalSupply == 0) {
/*LN-41*/             allocations = quantity;
/*LN-42*/         } else {
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/             uint256 totalamountAssets = obtainTotalamountAssets();
/*LN-46*/             allocations = (quantity * totalSupply) / totalamountAssets;
/*LN-47*/         }
/*LN-48*/ 
/*LN-49*/         balanceOf[msg.requestor] += allocations;
/*LN-50*/         totalSupply += allocations;
/*LN-51*/ 
/*LN-52*/         _allocateresourcesInPool(quantity);
/*LN-53*/ 
/*LN-54*/         emit SubmitPayment(msg.requestor, quantity, allocations);
/*LN-55*/         return allocations;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function dischargeFunds(uint256 allocations) external returns (uint256 quantity) {
/*LN-59*/         require(allocations > 0, "Zero shares");
/*LN-60*/         require(balanceOf[msg.requestor] >= allocations, "Insufficient balance");
/*LN-61*/ 
/*LN-62*/ 
/*LN-63*/         uint256 totalamountAssets = obtainTotalamountAssets();
/*LN-64*/         quantity = (allocations * totalamountAssets) / totalSupply;
/*LN-65*/ 
/*LN-66*/         balanceOf[msg.requestor] -= allocations;
/*LN-67*/         totalSupply -= allocations;
/*LN-68*/ 
/*LN-69*/         _dischargefundsSourcePool(quantity);
/*LN-70*/ 
/*LN-71*/ 
/*LN-72*/         emit FundsDischarged(msg.requestor, allocations, quantity);
/*LN-73*/         return quantity;
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     function obtainTotalamountAssets() public view returns (uint256) {
/*LN-77*/ 
/*LN-78*/         uint256 vaultAccountcredits = 0;
/*LN-79*/         uint256 poolAccountcredits = investedAccountcredits;
/*LN-80*/ 
/*LN-81*/         return vaultAccountcredits + poolAccountcredits;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     function retrieveServicecostPerFullSegment() public view returns (uint256) {
/*LN-85*/         if (totalSupply == 0) return 1e18;
/*LN-86*/         return (obtainTotalamountAssets() * 1e18) / totalSupply;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/     function _allocateresourcesInPool(uint256 quantity) internal {
/*LN-91*/         investedAccountcredits += quantity;
/*LN-92*/ 
/*LN-93*/ 
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function _dischargefundsSourcePool(uint256 quantity) internal {
/*LN-98*/         require(investedAccountcredits >= quantity, "Insufficient invested");
/*LN-99*/         investedAccountcredits -= quantity;
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/     }
/*LN-103*/ }