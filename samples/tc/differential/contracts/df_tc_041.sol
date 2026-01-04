/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface ISmartLoan {
/*LN-19*/     function swapDebtParaSwap(
/*LN-20*/         bytes32 _fromAsset,
/*LN-21*/         bytes32 _toAsset,
/*LN-22*/         uint256 _repayAmount,
/*LN-23*/         uint256 _borrowAmount,
/*LN-24*/         bytes4 selector,
/*LN-25*/         bytes memory data
/*LN-26*/     ) external;
/*LN-27*/ 
/*LN-28*/     function claimReward(address pair, uint256[] calldata ids) external;
/*LN-29*/ }
/*LN-30*/ 
/*LN-31*/ contract SmartLoansFactory {
/*LN-32*/     address public admin;
/*LN-33*/     mapping(address => bool) public allowedPairs;
/*LN-34*/ 
/*LN-35*/     constructor() {
/*LN-36*/         admin = msg.sender;
/*LN-37*/     }
/*LN-38*/ 
/*LN-39*/     function addAllowedPair(address pair) external {
/*LN-40*/         require(msg.sender == admin, "Not admin");
/*LN-41*/         allowedPairs[pair] = true;
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     function createLoan() external returns (address) {
/*LN-45*/         SmartLoan loan = new SmartLoan(address(this));
/*LN-46*/         return address(loan);
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     function upgradePool(
/*LN-50*/         address poolProxy,
/*LN-51*/         address newImplementation
/*LN-52*/     ) external {
/*LN-53*/         require(msg.sender == admin, "Not admin");
/*LN-54*/     }
/*LN-55*/ }
/*LN-56*/ 
/*LN-57*/ contract SmartLoan is ISmartLoan {
/*LN-58*/     mapping(bytes32 => uint256) public deposits;
/*LN-59*/     mapping(bytes32 => uint256) public debts;
/*LN-60*/     SmartLoansFactory public factory;
/*LN-61*/ 
/*LN-62*/     constructor(address _factory) {
/*LN-63*/         factory = SmartLoansFactory(_factory);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function swapDebtParaSwap(
/*LN-67*/         bytes32 _fromAsset,
/*LN-68*/         bytes32 _toAsset,
/*LN-69*/         uint256 _repayAmount,
/*LN-70*/         uint256 _borrowAmount,
/*LN-71*/         bytes4 selector,
/*LN-72*/         bytes memory data
/*LN-73*/     ) external override {}
/*LN-74*/ 
/*LN-75*/     function claimReward(
/*LN-76*/         address pair,
/*LN-77*/         uint256[] calldata ids
/*LN-78*/     ) external override {
/*LN-79*/         require(factory.allowedPairs(pair), "Pair not allowed");
/*LN-80*/         (bool success, ) = pair.call(
/*LN-81*/             abi.encodeWithSignature("claimRewards(address)", msg.sender)
/*LN-82*/         );
/*LN-83*/     }
/*LN-84*/ }
/*LN-85*/ 