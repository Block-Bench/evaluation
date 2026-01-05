/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface ISmartLoan {
/*LN-18*/     function swapDebtParaSwap(
/*LN-19*/         bytes32 _fromAsset,
/*LN-20*/         bytes32 _toAsset,
/*LN-21*/         uint256 _repayAmount,
/*LN-22*/         uint256 _borrowAmount,
/*LN-23*/         bytes4 selector,
/*LN-24*/         bytes memory data
/*LN-25*/     ) external;
/*LN-26*/ 
/*LN-27*/     function claimReward(address pair, uint256[] calldata ids) external;
/*LN-28*/ }
/*LN-29*/ 
/*LN-30*/ contract SmartLoansFactory {
/*LN-31*/     address public admin;
/*LN-32*/ 
/*LN-33*/     constructor() {
/*LN-34*/         admin = msg.sender;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function createLoan() external returns (address) {
/*LN-38*/         SmartLoan loan = new SmartLoan();
/*LN-39*/         return address(loan);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function upgradePool(
/*LN-43*/         address poolProxy,
/*LN-44*/         address newImplementation
/*LN-45*/     ) external {
/*LN-46*/ 
/*LN-47*/         require(msg.sender == admin, "Not admin");
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/     }
/*LN-51*/ }
/*LN-52*/ 
/*LN-53*/ contract SmartLoan is ISmartLoan {
/*LN-54*/     mapping(bytes32 => uint256) public deposits;
/*LN-55*/     mapping(bytes32 => uint256) public debts;
/*LN-56*/ 
/*LN-57*/     function swapDebtParaSwap(
/*LN-58*/         bytes32 _fromAsset,
/*LN-59*/         bytes32 _toAsset,
/*LN-60*/         uint256 _repayAmount,
/*LN-61*/         uint256 _borrowAmount,
/*LN-62*/         bytes4 selector,
/*LN-63*/         bytes memory data
/*LN-64*/     ) external override {
/*LN-65*/ 
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/     function claimReward(
/*LN-70*/         address pair,
/*LN-71*/         uint256[] calldata ids
/*LN-72*/     ) external override {
/*LN-73*/ 
/*LN-74*/ 
/*LN-75*/         (bool success, ) = pair.call(
/*LN-76*/             abi.encodeWithSignature("claimRewards(address)", msg.sender)
/*LN-77*/         );
/*LN-78*/ 
/*LN-79*/     }
/*LN-80*/ }