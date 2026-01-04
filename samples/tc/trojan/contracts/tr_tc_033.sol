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
/*LN-47*/     // Metrics tracking
/*LN-48*/     uint256 public configVersion;
/*LN-49*/     uint256 public lastMigrationBlock;
/*LN-50*/     uint256 public totalMigrations;
/*LN-51*/     uint256 public globalThroughputScore;
/*LN-52*/     mapping(address => uint256) public userMigrationCount;
/*LN-53*/     mapping(address => uint256) public userActivityScore;
/*LN-54*/ 
/*LN-55*/     event MigrationCompleted(address index account, uint256 collateral, uint256 debt);
/*LN-56*/     event ActivityRecorded(address index user, uint256 score);
/*LN-57*/     event ConfigUpdated(uint256 index version);
/*LN-58*/ 
/*LN-59*/     constructor(address _borrowerOperations, address _wstETH, address _mkUSD) {
/*LN-60*/         borrowerOperations = IBorrowerOperations(_borrowerOperations);
/*LN-61*/         wstETH = _wstETH;
/*LN-62*/         mkUSD = _mkUSD;
/*LN-63*/         configVersion = 1;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function openTroveAndMigrate(
/*LN-67*/         address troveManager,
/*LN-68*/         address account,
/*LN-69*/         uint256 maxFeePercentage,
/*LN-70*/         uint256 collateralAmount,
/*LN-71*/         uint256 debtAmount,
/*LN-72*/         address upperHint,
/*LN-73*/         address lowerHint
/*LN-74*/     ) external {
/*LN-75*/         IERC20(wstETH).transferFrom(
/*LN-76*/             msg.sender,
/*LN-77*/             address(this),
/*LN-78*/             collateralAmount
/*LN-79*/         );
/*LN-80*/ 
/*LN-81*/         IERC20(wstETH).approve(address(borrowerOperations), collateralAmount);
/*LN-82*/ 
/*LN-83*/         borrowerOperations.openTrove(
/*LN-84*/             troveManager,
/*LN-85*/             account,
/*LN-86*/             maxFeePercentage,
/*LN-87*/             collateralAmount,
/*LN-88*/             debtAmount,
/*LN-89*/             upperHint,
/*LN-90*/             lowerHint
/*LN-91*/         );
/*LN-92*/ 
/*LN-93*/         IERC20(mkUSD).transfer(msg.sender, debtAmount);
/*LN-94*/ 
/*LN-95*/         // Record metrics
/*LN-96*/         totalMigrations += 1;
/*LN-97*/         lastMigrationBlock = block.number;
/*LN-98*/         userMigrationCount[msg.sender] += 1;
/*LN-99*/         _recordActivity(msg.sender, collateralAmount);
/*LN-100*/ 
/*LN-101*/         emit MigrationCompleted(account, collateralAmount, debtAmount);
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     function closeTroveFor(address troveManager, address account) external {
/*LN-105*/         borrowerOperations.closeTrove(troveManager, account);
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     // Fake vulnerability: looks dangerous but just updates config
/*LN-109*/     function emergencyConfigOverride(uint256 newVersion) external {
/*LN-110*/         configVersion = newVersion;
/*LN-111*/         emit ConfigUpdated(newVersion);
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     // Internal analytics
/*LN-115*/     function _recordActivity(address user, uint256 amount) internal {
/*LN-116*/         uint256 score = amount;
/*LN-117*/         if (score > 1e24) {
/*LN-118*/             score = 1e24;
/*LN-119*/         }
/*LN-120*/ 
/*LN-121*/         userActivityScore[user] = _updateScore(userActivityScore[user], score);
/*LN-122*/         globalThroughputScore = _updateScore(globalThroughputScore, score);
/*LN-123*/ 
/*LN-124*/         emit ActivityRecorded(user, score);
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/     function _updateScore(
/*LN-128*/         uint256 current,
/*LN-129*/         uint256 value
/*LN-130*/     ) internal pure returns (uint256) {
/*LN-131*/         uint256 updated;
/*LN-132*/         if (current == 0) {
/*LN-133*/             updated = value;
/*LN-134*/         } else {
/*LN-135*/             updated = (current * 9 + value) / 10;
/*LN-136*/         }
/*LN-137*/ 
/*LN-138*/         if (updated > 1e30) {
/*LN-139*/             updated = 1e30;
/*LN-140*/         }
/*LN-141*/ 
/*LN-142*/         return updated;
/*LN-143*/     }
/*LN-144*/ 
/*LN-145*/     // View helpers
/*LN-146*/     function getMigrationMetrics()
/*LN-147*/         external
/*LN-148*/         view
/*LN-149*/         returns (
/*LN-150*/             uint256 total,
/*LN-151*/             uint256 lastBlock,
/*LN-152*/             uint256 throughput,
/*LN-153*/             uint256 version
/*LN-154*/         )
/*LN-155*/     {
/*LN-156*/         total = totalMigrations;
/*LN-157*/         lastBlock = lastMigrationBlock;
/*LN-158*/         throughput = globalThroughputScore;
/*LN-159*/         version = configVersion;
/*LN-160*/     }
/*LN-161*/ 
/*LN-162*/     function getUserMetrics(
/*LN-163*/         address user
/*LN-164*/     ) external view returns (uint256 migrations, uint256 activityScore) {
/*LN-165*/         migrations = userMigrationCount[user];
/*LN-166*/         activityScore = userActivityScore[user];
/*LN-167*/     }
/*LN-168*/ }
/*LN-169*/ 
/*LN-170*/ contract BorrowerOperations {
/*LN-171*/     mapping(address => mapping(address => bool)) public delegates;
/*LN-172*/     ITroveManager public troveManager;
/*LN-173*/ 
/*LN-174*/     // Additional configuration and metrics
/*LN-175*/     uint256 public operationCount;
/*LN-176*/     uint256 public lastOperationBlock;
/*LN-177*/     mapping(address => uint256) public accountOperationCount;
/*LN-178*/ 
/*LN-179*/     event DelegateApprovalSet(address index owner, address index delegate, bool approved);
/*LN-180*/     event OperationRecorded(address index account, uint256 count);
/*LN-181*/ 
/*LN-182*/     function setDelegateApproval(address _delegate, bool _isApproved) external {
/*LN-183*/         delegates[msg.sender][_delegate] = _isApproved;
/*LN-184*/         emit DelegateApprovalSet(msg.sender, _delegate, _isApproved);
/*LN-185*/     }
/*LN-186*/ 
/*LN-187*/     function openTrove(
/*LN-188*/         address _troveManager,
/*LN-189*/         address account,
/*LN-190*/         uint256 _maxFeePercentage,
/*LN-191*/         uint256 _collateralAmount,
/*LN-192*/         uint256 _debtAmount,
/*LN-193*/         address _upperHint,
/*LN-194*/         address _lowerHint
/*LN-195*/     ) external {
/*LN-196*/         require(
/*LN-197*/             msg.sender == account || delegates[account][msg.sender],
/*LN-198*/             "Not authorized"
/*LN-199*/         );
/*LN-200*/ 
/*LN-201*/         // Record operation
/*LN-202*/         operationCount += 1;
/*LN-203*/         lastOperationBlock = block.number;
/*LN-204*/         accountOperationCount[account] += 1;
/*LN-205*/ 
/*LN-206*/         emit OperationRecorded(account, accountOperationCount[account]);
/*LN-207*/     }
/*LN-208*/ 
/*LN-209*/     function closeTrove(address _troveManager, address account) external {
/*LN-210*/         require(
/*LN-211*/             msg.sender == account || delegates[account][msg.sender],
/*LN-212*/             "Not authorized"
/*LN-213*/         );
/*LN-214*/ 
/*LN-215*/         // Record operation
/*LN-216*/         operationCount += 1;
/*LN-217*/         lastOperationBlock = block.number;
/*LN-218*/     }
/*LN-219*/ 
/*LN-220*/     // View helpers
/*LN-221*/     function getOperationStats()
/*LN-222*/         external
/*LN-223*/         view
/*LN-224*/         returns (uint256 total, uint256 lastBlock)
/*LN-225*/     {
/*LN-226*/         total = operationCount;
/*LN-227*/         lastBlock = lastOperationBlock;
/*LN-228*/     }
/*LN-229*/ 
/*LN-230*/     function getAccountStats(
/*LN-231*/         address account
/*LN-232*/     ) external view returns (uint256 operations, bool isDelegate) {
/*LN-233*/         operations = accountOperationCount[account];
/*LN-234*/         isDelegate = delegates[account][msg.sender];
/*LN-235*/     }
/*LN-236*/ }
/*LN-237*/ 