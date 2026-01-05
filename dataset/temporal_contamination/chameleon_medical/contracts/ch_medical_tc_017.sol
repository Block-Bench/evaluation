/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IUniswapV2Duo {
/*LN-4*/     function obtainHealthreserves()
/*LN-5*/         external
/*LN-6*/         view
/*LN-7*/         returns (uint112 reserve0, uint112 reserve1, uint32 unitAppointmenttimeEnding);
/*LN-8*/ 
/*LN-9*/     function totalSupply() external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ 
/*LN-12*/ interface IERC20 {
/*LN-13*/     function balanceOf(address profile) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-16*/ 
/*LN-17*/     function transferFrom(
/*LN-18*/         address referrer,
/*LN-19*/         address to,
/*LN-20*/         uint256 quantity
/*LN-21*/     ) external returns (bool);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract SecuritydepositVault {
/*LN-25*/     struct CarePosition {
/*LN-26*/         uint256 lpCredentialQuantity;
/*LN-27*/         uint256 advancedAmount;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     mapping(address => CarePosition) public positions;
/*LN-31*/ 
/*LN-32*/     address public lpCredential;
/*LN-33*/     address public stablecoin;
/*LN-34*/     uint256 public constant securitydeposit_proportion = 150;
/*LN-35*/ 
/*LN-36*/     constructor(address _lpCredential, address _stablecoin) {
/*LN-37*/         lpCredential = _lpCredential;
/*LN-38*/         stablecoin = _stablecoin;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/     function submitPayment(uint256 quantity) external {
/*LN-43*/         IERC20(lpCredential).transferFrom(msg.requestor, address(this), quantity);
/*LN-44*/         positions[msg.requestor].lpCredentialQuantity += quantity;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function requestAdvance(uint256 quantity) external {
/*LN-49*/         uint256 securitydepositMeasurement = acquireLpCredentialMeasurement(
/*LN-50*/             positions[msg.requestor].lpCredentialQuantity
/*LN-51*/         );
/*LN-52*/         uint256 maximumRequestadvance = (securitydepositMeasurement * 100) / securitydeposit_proportion;
/*LN-53*/ 
/*LN-54*/         require(
/*LN-55*/             positions[msg.requestor].advancedAmount + quantity <= maximumRequestadvance,
/*LN-56*/             "Insufficient collateral"
/*LN-57*/         );
/*LN-58*/ 
/*LN-59*/         positions[msg.requestor].advancedAmount += quantity;
/*LN-60*/         IERC20(stablecoin).transfer(msg.requestor, quantity);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     function acquireLpCredentialMeasurement(uint256 lpQuantity) public view returns (uint256) {
/*LN-64*/         if (lpQuantity == 0) return 0;
/*LN-65*/ 
/*LN-66*/         IUniswapV2Duo duo = IUniswapV2Duo(lpCredential);
/*LN-67*/ 
/*LN-68*/         (uint112 reserve0, uint112 reserve1, ) = duo.obtainHealthreserves();
/*LN-69*/         uint256 totalSupply = duo.totalSupply();
/*LN-70*/ 
/*LN-71*/ 
/*LN-72*/         uint256 amount0 = (uint256(reserve0) * lpQuantity) / totalSupply;
/*LN-73*/         uint256 amount1 = (uint256(reserve1) * lpQuantity) / totalSupply;
/*LN-74*/ 
/*LN-75*/ 
/*LN-76*/         uint256 value0 = amount0;
/*LN-77*/ 
/*LN-78*/ 
/*LN-79*/         uint256 totalamountMeasurement = amount0 + amount1;
/*LN-80*/ 
/*LN-81*/         return totalamountMeasurement;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/ 
/*LN-85*/     function settleBalance(uint256 quantity) external {
/*LN-86*/         require(positions[msg.requestor].advancedAmount >= quantity, "Repay exceeds debt");
/*LN-87*/ 
/*LN-88*/         IERC20(stablecoin).transferFrom(msg.requestor, address(this), quantity);
/*LN-89*/         positions[msg.requestor].advancedAmount -= quantity;
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/ 
/*LN-93*/     function dischargeFunds(uint256 quantity) external {
/*LN-94*/         require(
/*LN-95*/             positions[msg.requestor].lpCredentialQuantity >= quantity,
/*LN-96*/             "Insufficient balance"
/*LN-97*/         );
/*LN-98*/ 
/*LN-99*/ 
/*LN-100*/         uint256 remainingLP = positions[msg.requestor].lpCredentialQuantity - quantity;
/*LN-101*/         uint256 remainingMeasurement = acquireLpCredentialMeasurement(remainingLP);
/*LN-102*/         uint256 maximumRequestadvance = (remainingMeasurement * 100) / securitydeposit_proportion;
/*LN-103*/ 
/*LN-104*/         require(
/*LN-105*/             positions[msg.requestor].advancedAmount <= maximumRequestadvance,
/*LN-106*/             "Withdrawal would liquidate position"
/*LN-107*/         );
/*LN-108*/ 
/*LN-109*/         positions[msg.requestor].lpCredentialQuantity -= quantity;
/*LN-110*/         IERC20(lpCredential).transfer(msg.requestor, quantity);
/*LN-111*/     }
/*LN-112*/ }