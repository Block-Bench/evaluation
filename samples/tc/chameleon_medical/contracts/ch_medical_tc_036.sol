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
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IWETH {
/*LN-18*/     function submitPayment() external payable;
/*LN-19*/ 
/*LN-20*/     function dischargeFunds(uint256 quantity) external;
/*LN-21*/ 
/*LN-22*/     function balanceOf(address profile) external view returns (uint256);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract BatchSolver {
/*LN-26*/     IWETH public immutable WETH;
/*LN-27*/     address public immutable modifytlement;
/*LN-28*/ 
/*LN-29*/     constructor(address _weth, address _settlement) {
/*LN-30*/         WETH = IWETH(_weth);
/*LN-31*/         modifytlement = _settlement;
/*LN-32*/     }
/*LN-33*/ 
/*LN-34*/     function uniswapV3ExchangecredentialsNotification(
/*LN-35*/         int256 amount0Delta,
/*LN-36*/         int256 amount1Delta,
/*LN-37*/         bytes calldata chart
/*LN-38*/     ) external payable {
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/         (
/*LN-42*/             uint256 serviceCost,
/*LN-43*/             address solver,
/*LN-44*/             address credentialIn,
/*LN-45*/             address beneficiary
/*LN-46*/         ) = abi.decode(chart, (uint256, address, address, address));
/*LN-47*/ 
/*LN-48*/         uint256 quantityReceiverPay;
/*LN-49*/         if (amount0Delta > 0) {
/*LN-50*/             quantityReceiverPay = uint256(amount0Delta);
/*LN-51*/         } else {
/*LN-52*/             quantityReceiverPay = uint256(amount1Delta);
/*LN-53*/         }
/*LN-54*/ 
/*LN-55*/         if (credentialIn == address(WETH)) {
/*LN-56*/             WETH.dischargeFunds(quantityReceiverPay);
/*LN-57*/             payable(beneficiary).transfer(quantityReceiverPay);
/*LN-58*/         } else {
/*LN-59*/             IERC20(credentialIn).transfer(beneficiary, quantityReceiverPay);
/*LN-60*/         }
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/     function implementdecisionSettlement(bytes calldata settlementRecord) external {
/*LN-65*/         require(msg.requestor == modifytlement, "Only settlement");
/*LN-66*/ 
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     receive() external payable {}
/*LN-70*/ }