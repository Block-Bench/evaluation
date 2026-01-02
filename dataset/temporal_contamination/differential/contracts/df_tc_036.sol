/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IBorrowerOperations {
/*LN-16*/     function setDelegateApproval(address _delegate, bool _isApproved) external;
/*LN-17*/     function openTrove(
/*LN-18*/         address troveManager,
/*LN-19*/         address account,
/*LN-20*/         uint256 _maxFeePercentage,
/*LN-21*/         uint256 _collateralAmount,
/*LN-22*/         uint256 _debtAmount,
/*LN-23*/         address _upperHint,
/*LN-24*/         address _lowerHint
/*LN-25*/     ) external;
/*LN-26*/     function closeTrove(address troveManager, address account) external;
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ interface ITroveManager {
/*LN-30*/     function getTroveCollAndDebt(
/*LN-31*/         address _borrower
/*LN-32*/     ) external view returns (uint256 coll, uint256 debt);
/*LN-33*/     function liquidate(address _borrower) external;
/*LN-34*/ }
/*LN-35*/ 
/*LN-36*/ contract MigrateTroveZap {
/*LN-37*/     IBorrowerOperations public borrowerOperations;
/*LN-38*/     address public wstETH;
/*LN-39*/     address public mkUSD;
/*LN-40*/ 
/*LN-41*/     constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
/*LN-42*/     borrowerOperations = IBorrowerOperations(_borrowerOperations);
/*LN-43*/     wstETH = _wstETH;
/*LN-44*/     mkUSD = _mkUSD;
/*LN-45*/     }
/*LN-46*/     function openTroveAndMigrate(
/*LN-47*/         address troveManager,
/*LN-48*/         address account,
/*LN-49*/         uint256 maxFeePercentage,
/*LN-50*/         uint256 collateralAmount,
/*LN-51*/         uint256 debtAmount,
/*LN-52*/         address upperHint,
/*LN-53*/         address lowerHint
/*LN-54*/     ) external {
/*LN-55*/         require(account == msg.sender, "Account must be caller");
/*LN-56*/         IERC20(wstETH).transferFrom(
/*LN-57*/             msg.sender,
/*LN-58*/             address(this),
/*LN-59*/             collateralAmount
/*LN-60*/         );
/*LN-61*/ 
/*LN-62*/         IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);
/*LN-63*/ 
/*LN-64*/         borrowerOperations.openTrove(
/*LN-65*/             troveManager,
/*LN-66*/             account,
/*LN-67*/             maxFeePercentage,
/*LN-68*/             collateralAmount,
/*LN-69*/             debtAmount,
/*LN-70*/             upperHint,
/*LN-71*/             lowerHint
/*LN-72*/         );
/*LN-73*/ 
/*LN-74*/         IERC20(mkUSD).transfer(msg.sender, debtAmount);
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function closeTroveFor(address troveManager, address account) external {
/*LN-78*/         require(account == msg.sender, "Account must be caller");
/*LN-79*/         borrowerOperations.closeTrove(troveManager, account);
/*LN-80*/     }
/*LN-81*/ }
/*LN-82*/ 
/*LN-83*/ contract BorrowerOperations {
/*LN-84*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-85*/     ITroveManager public troveManager;
/*LN-86*/ 
/*LN-87*/     function setDelegateApproval(address _delegate, bool _isApproved) external {
/*LN-88*/         delegates[msg.sender][_delegate] = _isApproved;
/*LN-89*/     }
/*LN-90*/ 
/*LN-91*/     function openTrove(
/*LN-92*/         address _troveManager,
/*LN-93*/         address account,
/*LN-94*/         uint256 _maxFeePercentage,
/*LN-95*/         uint256 _collateralAmount,
/*LN-96*/         uint256 _debtAmount,
/*LN-97*/         address _upperHint,
/*LN-98*/         address _lowerHint
/*LN-99*/     ) external {
/*LN-100*/         require(
/*LN-101*/             msg.sender == account || delegates[account][msg.sender],
/*LN-102*/             "Not authorized"
/*LN-103*/         );
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/     function closeTrove(address _troveManager, address account) external {
/*LN-107*/         require(
/*LN-108*/             msg.sender == account || delegates[account][msg.sender],
/*LN-109*/             "Not authorized"
/*LN-110*/         );
/*LN-111*/     }
/*LN-112*/ }
/*LN-113*/ 