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
/*LN-66*/ 
/*LN-67*/         // Transfer collateral from msg.sender
/*LN-68*/         IERC20(wstETH).transferFrom(
/*LN-69*/             msg.sender,
/*LN-70*/             address(this),
/*LN-71*/             collateralAmount
/*LN-72*/         );
/*LN-73*/ 
/*LN-74*/         
/*LN-75*/         IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);
/*LN-76*/ 
/*LN-77*/         borrowerOperations.openTrove(
/*LN-78*/             troveManager,
/*LN-79*/             account,
/*LN-80*/             maxFeePercentage,
/*LN-81*/             collateralAmount,
/*LN-82*/             debtAmount,
/*LN-83*/             upperHint,
/*LN-84*/             lowerHint
/*LN-85*/         );
/*LN-86*/ 
/*LN-87*/         IERC20(mkUSD).transfer(msg.sender, debtAmount);
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     /**
/*LN-91*/      * @notice Close a trove for an account
/*LN-92*/      */
/*LN-93*/     function closeTroveFor(address troveManager, address account) external {
/*LN-94*/         // And extract the collateral
/*LN-95*/ 
/*LN-96*/         borrowerOperations.closeTrove(troveManager, account);
/*LN-97*/     }
/*LN-98*/ }
/*LN-99*/ 
/*LN-100*/ contract BorrowerOperations {
/*LN-101*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-102*/     ITroveManager public troveManager;
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Set delegate approval
/*LN-106*/      * @dev Users can approve contracts to act on their behalf
/*LN-107*/      */
/*LN-108*/     function setDelegateApproval(address _delegate, bool _isApproved) external {
/*LN-109*/         delegates[msg.sender][_delegate] = _isApproved;
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/     /**
/*LN-113*/      * @notice Open a new trove
/*LN-114*/      */
/*LN-115*/     function openTrove(
/*LN-116*/         address _troveManager,
/*LN-117*/         address account,
/*LN-118*/         uint256 _maxFeePercentage,
/*LN-119*/         uint256 _collateralAmount,
/*LN-120*/         uint256 _debtAmount,
/*LN-121*/         address _upperHint,
/*LN-122*/         address _lowerHint
/*LN-123*/     ) external {
/*LN-124*/         
/*LN-125*/         
/*LN-126*/         require(
/*LN-127*/             msg.sender == account || delegates[account][msg.sender],
/*LN-128*/             "Not authorized"
/*LN-129*/         );
/*LN-130*/ 
/*LN-131*/         // Open trove logic (simplified)
/*LN-132*/         // Creates debt position for 'account' with provided collateral
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     /**
/*LN-136*/      * @notice Close a trove
/*LN-137*/      */
/*LN-138*/     function closeTrove(address _troveManager, address account) external {
/*LN-139*/         require(
/*LN-140*/             msg.sender == account || delegates[account][msg.sender],
/*LN-141*/             "Not authorized"
/*LN-142*/         );
/*LN-143*/ 
/*LN-144*/         // Close trove logic (simplified)
/*LN-145*/     }
/*LN-146*/ }
/*LN-147*/ 