/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * PRISMA FINANCE EXPLOIT (March 2024)
/*LN-6*/  * Loss: $10 million
/*LN-7*/  * Attack: Delegate Approval Vulnerability in MigrateTroveZap
/*LN-8*/  *
/*LN-9*/  * Prisma Finance is a CDP (Collateralized Debt Position) protocol similar to Liquity.
/*LN-10*/  * The MigrateTroveZap contract had a vulnerability where it accepted user-controlled
/*LN-11*/  * account parameters in operations, allowing attackers to manipulate other users' troves
/*LN-12*/  * through delegate approvals.
/*LN-13*/  */
/*LN-14*/ 
/*LN-15*/ interface IERC20 {
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ 
/*LN-24*/     function balanceOf(address account) external view returns (uint256);
/*LN-25*/ 
/*LN-26*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ interface IBorrowerOperations {
/*LN-30*/     function setDelegateApproval(address _delegate, bool _isApproved) external;
/*LN-31*/ 
/*LN-32*/     function openTrove(
/*LN-33*/         address troveManager,
/*LN-34*/         address account,
/*LN-35*/         uint256 _maxFeePercentage,
/*LN-36*/         uint256 _collateralAmount,
/*LN-37*/         uint256 _debtAmount,
/*LN-38*/         address _upperHint,
/*LN-39*/         address _lowerHint
/*LN-40*/     ) external;
/*LN-41*/ 
/*LN-42*/     function closeTrove(address troveManager, address account) external;
/*LN-43*/ }
/*LN-44*/ 
/*LN-45*/ interface ITroveManager {
/*LN-46*/     function getTroveCollAndDebt(
/*LN-47*/         address _borrower
/*LN-48*/     ) external view returns (uint256 coll, uint256 debt);
/*LN-49*/ 
/*LN-50*/     function liquidate(address _borrower) external;
/*LN-51*/ }
/*LN-52*/ 
/*LN-53*/ contract MigrateTroveZap {
/*LN-54*/     IBorrowerOperations public borrowerOperations;
/*LN-55*/     address public wstETH;
/*LN-56*/     address public mkUSD;
/*LN-57*/ 
/*LN-58*/     constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
/*LN-59*/         borrowerOperations = _borrowerOperations;
/*LN-60*/         wstETH = _wstETH;
/*LN-61*/         mkUSD = _mkUSD;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Migrate trove from one system to another
/*LN-66*/      * @dev VULNERABLE: User-controlled account parameter
/*LN-67*/      */
/*LN-68*/     function openTroveAndMigrate(
/*LN-69*/         address troveManager,
/*LN-70*/         address account,
/*LN-71*/         uint256 maxFeePercentage,
/*LN-72*/         uint256 collateralAmount,
/*LN-73*/         uint256 debtAmount,
/*LN-74*/         address upperHint,
/*LN-75*/         address lowerHint
/*LN-76*/     ) external {
/*LN-77*/         // VULNERABILITY 1: Accepts user-controlled 'account' parameter
/*LN-78*/         // Attacker can specify another user's address as 'account'
/*LN-79*/         // If that user previously approved this contract as delegate, it can act on their behalf
/*LN-80*/ 
/*LN-81*/         // Transfer collateral from msg.sender
/*LN-82*/         IERC20(wstETH).transferFrom(
/*LN-83*/             msg.sender,
/*LN-84*/             address(this),
/*LN-85*/             collateralAmount
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         // VULNERABILITY 2: Opens trove on behalf of arbitrary 'account' address
/*LN-89*/         // If victim approved this contract, this call succeeds
/*LN-90*/         // Opens trove using attacker's collateral but victim's account
/*LN-91*/         IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);
/*LN-92*/ 
/*LN-93*/         borrowerOperations.openTrove(
/*LN-94*/             troveManager,
/*LN-95*/             account,
/*LN-96*/             maxFeePercentage,
/*LN-97*/             collateralAmount,
/*LN-98*/             debtAmount,
/*LN-99*/             upperHint,
/*LN-100*/             lowerHint
/*LN-101*/         );
/*LN-102*/ 
/*LN-103*/         // VULNERABILITY 3: Transfers minted debt tokens to msg.sender (attacker)
/*LN-104*/         // Attacker gets the debt tokens while victim's account gets the debt
/*LN-105*/         IERC20(mkUSD).transfer(msg.sender, debtAmount);
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     /**
/*LN-109*/      * @notice Close a trove for an account
/*LN-110*/      * @dev VULNERABLE: Can close any account's trove if delegate approved
/*LN-111*/      */
/*LN-112*/     function closeTroveFor(address troveManager, address account) external {
/*LN-113*/         // VULNERABILITY 4: Can close arbitrary account's trove
/*LN-114*/         // If attacker pays off the debt, they can force close victim's trove
/*LN-115*/         // And extract the collateral
/*LN-116*/ 
/*LN-117*/         borrowerOperations.closeTrove(troveManager, account);
/*LN-118*/     }
/*LN-119*/ }
/*LN-120*/ 
/*LN-121*/ contract BorrowerOperations {
/*LN-122*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-123*/     ITroveManager public troveManager;
/*LN-124*/ 
/*LN-125*/     /**
/*LN-126*/      * @notice Set delegate approval
/*LN-127*/      * @dev Users can approve contracts to act on their behalf
/*LN-128*/      */
/*LN-129*/     function setDelegateApproval(address _delegate, bool _isApproved) external {
/*LN-130*/         delegates[msg.sender][_delegate] = _isApproved;
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     /**
/*LN-134*/      * @notice Open a new trove
/*LN-135*/      * @dev VULNERABLE: No check if msg.sender == account when delegate is approved
/*LN-136*/      */
/*LN-137*/     function openTrove(
/*LN-138*/         address _troveManager,
/*LN-139*/         address account,
/*LN-140*/         uint256 _maxFeePercentage,
/*LN-141*/         uint256 _collateralAmount,
/*LN-142*/         uint256 _debtAmount,
/*LN-143*/         address _upperHint,
/*LN-144*/         address _lowerHint
/*LN-145*/     ) external {
/*LN-146*/         // VULNERABILITY 5: Insufficient authorization check
/*LN-147*/         // Only checks if msg.sender is approved delegate
/*LN-148*/         // Doesn't validate that delegate should be able to open troves on behalf of account
/*LN-149*/         require(
/*LN-150*/             msg.sender == account || delegates[account][msg.sender],
/*LN-151*/             "Not authorized"
/*LN-152*/         );
/*LN-153*/ 
/*LN-154*/         // Open trove logic (simplified)
/*LN-155*/         // Creates debt position for 'account' with provided collateral
/*LN-156*/     }
/*LN-157*/ 
/*LN-158*/     /**
/*LN-159*/      * @notice Close a trove
/*LN-160*/      */
/*LN-161*/     function closeTrove(address _troveManager, address account) external {
/*LN-162*/         require(
/*LN-163*/             msg.sender == account || delegates[account][msg.sender],
/*LN-164*/             "Not authorized"
/*LN-165*/         );
/*LN-166*/ 
/*LN-167*/         // Close trove logic (simplified)
/*LN-168*/     }
/*LN-169*/ }
/*LN-170*/ 
/*LN-171*/ /**
/*LN-172*/  * EXPLOIT SCENARIO:
/*LN-173*/  *
/*LN-174*/  * 1. Attacker identifies victims who approved MigrateTroveZap as delegate:
/*LN-175*/  *    - Many users approved zap contracts for convenience
/*LN-176*/  *    - These approvals were intended for legitimate migrations
/*LN-177*/  *
/*LN-178*/  * 2. Attacker obtains flashloan (~1800 wstETH):
/*LN-179*/  *    - Borrows collateral to fund the attack
/*LN-180*/  *
/*LN-181*/  * 3. Attacker calls openTroveAndMigrate():
/*LN-182*/  *    - Passes victim's address as 'account' parameter
/*LN-183*/  *    - Provides attacker's collateral (from flashloan)
/*LN-184*/  *    - Mints maximum debt (mkUSD) against victim's account
/*LN-185*/  *
/*LN-186*/  * 4. Zap contract opens trove on victim's behalf:
/*LN-187*/  *    - Uses delegate approval to authorize the operation
/*LN-188*/  *    - Opens trove with attacker's collateral but victim's account
/*LN-189*/  *    - Mints debt tokens to attacker (msg.sender)
/*LN-190*/  *
/*LN-191*/  * 5. Attacker receives minted debt tokens:
/*LN-192*/  *    - Gets full amount of mkUSD (debt tokens)
/*LN-193*/  *    - Victim's account now has debt obligation
/*LN-194*/  *
/*LN-195*/  * 6. Attacker closes their own position:
/*LN-196*/  *    - Can pay off debt or manipulate price to liquidate
/*LN-197*/  *    - Extracts collateral if profitable
/*LN-198*/  *
/*LN-199*/  * 7. Repeat for multiple victims:
/*LN-200*/  *    - Drain $10M across multiple accounts
/*LN-201*/  *    - Repay flashloan with profits
/*LN-202*/  *
/*LN-203*/  * Root Causes:
/*LN-204*/  * - User-controlled account parameter in zap contract
/*LN-205*/  * - Overly permissive delegate approval system
/*LN-206*/  * - No distinction between different types of delegate permissions
/*LN-207*/  * - Missing msg.sender validation for sensitive operations
/*LN-208*/  * - Zap contract had unnecessary privileges
/*LN-209*/  * - No time-bounded or scope-limited approvals
/*LN-210*/  *
/*LN-211*/  * Fix:
/*LN-212*/  * - Always validate account == msg.sender for critical operations
/*LN-213*/  * - Implement granular permission system (specific operation approvals)
/*LN-214*/  * - Add time-bounded approvals with expiration
/*LN-215*/  * - Scope delegate permissions to specific operations
/*LN-216*/  * - Require explicit confirmation for debt-creating operations
/*LN-217*/  * - Implement maximum debt limits per delegation
/*LN-218*/  * - Add circuit breakers for unusual delegation patterns
/*LN-219*/  * - Revoke all existing delegate approvals and require re-approval
/*LN-220*/  */
/*LN-221*/ 