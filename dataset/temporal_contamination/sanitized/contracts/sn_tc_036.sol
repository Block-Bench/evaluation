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
/*LN-18*/ interface IBorrowerOperations {
/*LN-19*/     function setDelegateApproval(address _delegate, bool _isApproved) external;
/*LN-20*/ 
/*LN-21*/     function openTrove(
/*LN-22*/         address troveManager,
/*LN-23*/         address account,
/*LN-24*/         uint256 _maxFeePercentage,
/*LN-25*/         uint256 _collateralAmount,
/*LN-26*/         uint256 _debtAmount,
/*LN-27*/         address _upperHint,
/*LN-28*/         address _lowerHint
/*LN-29*/     ) external;
/*LN-30*/ 
/*LN-31*/     function closeTrove(address troveManager, address account) external;
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ interface ITroveManager {
/*LN-35*/     function getTroveCollAndDebt(
/*LN-36*/         address _borrower
/*LN-37*/     ) external view returns (uint256 coll, uint256 debt);
/*LN-38*/ 
/*LN-39*/     function liquidate(address _borrower) external;
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ contract MigrateTroveZap {
/*LN-43*/     IBorrowerOperations public borrowerOperations;
/*LN-44*/     address public wstETH;
/*LN-45*/     address public mkUSD;
/*LN-46*/ 
/*LN-47*/     constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
/*LN-48*/         borrowerOperations = _borrowerOperations;
/*LN-49*/         wstETH = _wstETH;
/*LN-50*/         mkUSD = _mkUSD;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     /**
/*LN-54*/      * @notice Migrate trove from one system to another
/*LN-55*/      */
/*LN-56*/     function openTroveAndMigrate(
/*LN-57*/         address troveManager,
/*LN-58*/         address account,
/*LN-59*/         uint256 maxFeePercentage,
/*LN-60*/         uint256 collateralAmount,
/*LN-61*/         uint256 debtAmount,
/*LN-62*/         address upperHint,
/*LN-63*/         address lowerHint
/*LN-64*/     ) external {
/*LN-65*/ 
/*LN-66*/         // Transfer collateral from msg.sender
/*LN-67*/         IERC20(wstETH).transferFrom(
/*LN-68*/             msg.sender,
/*LN-69*/             address(this),
/*LN-70*/             collateralAmount
/*LN-71*/         );
/*LN-72*/ 
/*LN-73*/         IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);
/*LN-74*/ 
/*LN-75*/         borrowerOperations.openTrove(
/*LN-76*/             troveManager,
/*LN-77*/             account,
/*LN-78*/             maxFeePercentage,
/*LN-79*/             collateralAmount,
/*LN-80*/             debtAmount,
/*LN-81*/             upperHint,
/*LN-82*/             lowerHint
/*LN-83*/         );
/*LN-84*/ 
/*LN-85*/         IERC20(mkUSD).transfer(msg.sender, debtAmount);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     /**
/*LN-89*/      * @notice Close a trove for an account
/*LN-90*/      */
/*LN-91*/     function closeTroveFor(address troveManager, address account) external {
/*LN-92*/         // And extract the collateral
/*LN-93*/ 
/*LN-94*/         borrowerOperations.closeTrove(troveManager, account);
/*LN-95*/     }
/*LN-96*/ }
/*LN-97*/ 
/*LN-98*/ contract BorrowerOperations {
/*LN-99*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-100*/     ITroveManager public troveManager;
/*LN-101*/ 
/*LN-102*/     /**
/*LN-103*/      * @notice Set delegate approval
/*LN-104*/      * @dev Users can approve contracts to act on their behalf
/*LN-105*/      */
/*LN-106*/     function setDelegateApproval(address _delegate, bool _isApproved) external {
/*LN-107*/         delegates[msg.sender][_delegate] = _isApproved;
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     /**
/*LN-111*/      * @notice Open a new trove
/*LN-112*/      */
/*LN-113*/     function openTrove(
/*LN-114*/         address _troveManager,
/*LN-115*/         address account,
/*LN-116*/         uint256 _maxFeePercentage,
/*LN-117*/         uint256 _collateralAmount,
/*LN-118*/         uint256 _debtAmount,
/*LN-119*/         address _upperHint,
/*LN-120*/         address _lowerHint
/*LN-121*/     ) external {
/*LN-122*/ 
/*LN-123*/         require(
/*LN-124*/             msg.sender == account || delegates[account][msg.sender],
/*LN-125*/             "Not authorized"
/*LN-126*/         );
/*LN-127*/ 
/*LN-128*/         // Open trove logic (simplified)
/*LN-129*/         // Creates debt position for 'account' with provided collateral
/*LN-130*/     }
/*LN-131*/ 
/*LN-132*/     /**
/*LN-133*/      * @notice Close a trove
/*LN-134*/      */
/*LN-135*/     function closeTrove(address _troveManager, address account) external {
/*LN-136*/         require(
/*LN-137*/             msg.sender == account || delegates[account][msg.sender],
/*LN-138*/             "Not authorized"
/*LN-139*/         );
/*LN-140*/ 
/*LN-141*/         // Close trove logic (simplified)
/*LN-142*/     }
/*LN-143*/ }
/*LN-144*/ 