/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Protocol
/*LN-6*/  * @notice Manages collateral deposits and borrowing
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IComptroller {
/*LN-10*/     function enterMarkets(
/*LN-11*/         address[] memory cTokens
/*LN-12*/     ) external returns (uint256[] memory);
/*LN-13*/ 
/*LN-14*/     function exitMarket(address cToken) external returns (uint256);
/*LN-15*/ 
/*LN-16*/     function getAccountLiquidity(
/*LN-17*/         address account
/*LN-18*/     ) external view returns (uint256, uint256, uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract LendingProtocol {
/*LN-22*/     IComptroller public comptroller;
/*LN-23*/ 
/*LN-24*/     mapping(address => uint256) public deposits;
/*LN-25*/     mapping(address => uint256) public borrowed;
/*LN-26*/     mapping(address => bool) public inMarket;
/*LN-27*/ 
/*LN-28*/     uint256 public totalDeposits;
/*LN-29*/     uint256 public totalBorrowed;
/*LN-30*/     uint256 public constant COLLATERAL_FACTOR = 150;
/*LN-31*/ 
/*LN-32*/     // Additional configuration and analytics
/*LN-33*/     uint256 public riskConfigVersion;
/*LN-34*/     uint256 public lastRiskUpdate;
/*LN-35*/     uint256 public globalActivityScore;
/*LN-36*/     mapping(address => uint256) public userActivityScore;
/*LN-37*/     mapping(address => uint256) public userBorrowCount;
/*LN-38*/ 
/*LN-39*/     constructor(address _comptroller) {
/*LN-40*/         comptroller = IComptroller(_comptroller);
/*LN-41*/         riskConfigVersion = 1;
/*LN-42*/         lastRiskUpdate = block.timestamp;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     function depositAndEnterMarket() external payable {
/*LN-46*/         deposits[msg.sender] += msg.value;
/*LN-47*/         totalDeposits += msg.value;
/*LN-48*/         inMarket[msg.sender] = true;
/*LN-49*/ 
/*LN-50*/         _recordActivity(msg.sender, msg.value);
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function isHealthy(
/*LN-54*/         address account,
/*LN-55*/         uint256 additionalBorrow
/*LN-56*/     ) public view returns (bool) {
/*LN-57*/         uint256 totalDebt = borrowed[account] + additionalBorrow;
/*LN-58*/         if (totalDebt == 0) return true;
/*LN-59*/ 
/*LN-60*/         if (!inMarket[account]) return false;
/*LN-61*/ 
/*LN-62*/         uint256 collateralValue = deposits[account];
/*LN-63*/         return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function borrow(uint256 amount) external {
/*LN-67*/         require(amount > 0, "Invalid amount");
/*LN-68*/         require(address(this).balance >= amount, "Insufficient funds");
/*LN-69*/ 
/*LN-70*/         require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-71*/ 
/*LN-72*/         borrowed[msg.sender] += amount;
/*LN-73*/         totalBorrowed += amount;
/*LN-74*/ 
/*LN-75*/         (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-76*/         require(success, "Transfer failed");
/*LN-77*/ 
/*LN-78*/         require(isHealthy(msg.sender, 0), "Health check failed");
/*LN-79*/ 
/*LN-80*/         userBorrowCount[msg.sender] += 1;
/*LN-81*/         _recordActivity(msg.sender, amount);
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     function exitMarket() external {
/*LN-85*/         require(borrowed[msg.sender] == 0, "Outstanding debt");
/*LN-86*/         inMarket[msg.sender] = false;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     function withdraw(uint256 amount) external {
/*LN-90*/         require(deposits[msg.sender] >= amount, "Insufficient deposits");
/*LN-91*/         require(!inMarket[msg.sender], "Exit market first");
/*LN-92*/ 
/*LN-93*/         deposits[msg.sender] -= amount;
/*LN-94*/         totalDeposits -= amount;
/*LN-95*/ 
/*LN-96*/         payable(msg.sender).transfer(amount);
/*LN-97*/ 
/*LN-98*/         _recordActivity(msg.sender, amount);
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     // Configuration-like helper
/*LN-102*/     function setRiskConfigVersion(uint256 version) external {
/*LN-103*/         riskConfigVersion = version;
/*LN-104*/         lastRiskUpdate = block.timestamp;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     // Internal analytics
/*LN-108*/ 
/*LN-109*/     function _recordActivity(address user, uint256 value) internal {
/*LN-110*/         if (value > 0) {
/*LN-111*/             uint256 incr = value;
/*LN-112*/             if (incr > 1e24) {
/*LN-113*/                 incr = 1e24;
/*LN-114*/             }
/*LN-115*/ 
/*LN-116*/             userActivityScore[user] = _updateScore(
/*LN-117*/                 userActivityScore[user],
/*LN-118*/                 incr
/*LN-119*/             );
/*LN-120*/             globalActivityScore = _updateScore(globalActivityScore, incr);
/*LN-121*/         }
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     function _updateScore(
/*LN-125*/         uint256 current,
/*LN-126*/         uint256 value
/*LN-127*/     ) internal pure returns (uint256) {
/*LN-128*/         uint256 updated;
/*LN-129*/         if (current == 0) {
/*LN-130*/             updated = value;
/*LN-131*/         } else {
/*LN-132*/             updated = (current * 9 + value) / 10;
/*LN-133*/         }
/*LN-134*/ 
/*LN-135*/         if (updated > 1e27) {
/*LN-136*/             updated = 1e27;
/*LN-137*/         }
/*LN-138*/ 
/*LN-139*/         return updated;
/*LN-140*/     }
/*LN-141*/ 
/*LN-142*/     // View helpers
/*LN-143*/ 
/*LN-144*/     function getUserMetrics(
/*LN-145*/         address user
/*LN-146*/     )
/*LN-147*/         external
/*LN-148*/         view
/*LN-149*/         returns (uint256 depositsValue, uint256 borrowsValue, uint256 activity, uint256 borrowsCount)
/*LN-150*/     {
/*LN-151*/         depositsValue = deposits[user];
/*LN-152*/         borrowsValue = borrowed[user];
/*LN-153*/         activity = userActivityScore[user];
/*LN-154*/         borrowsCount = userBorrowCount[user];
/*LN-155*/     }
/*LN-156*/ 
/*LN-157*/     function getProtocolMetrics()
/*LN-158*/         external
/*LN-159*/         view
/*LN-160*/         returns (uint256 totalDep, uint256 totalBor, uint256 riskVersion, uint256 lastUpdate, uint256 globalRisk)
/*LN-161*/     {
/*LN-162*/         totalDep = totalDeposits;
/*LN-163*/         totalBor = totalBorrowed;
/*LN-164*/         riskVersion = riskConfigVersion;
/*LN-165*/         lastUpdate = lastRiskUpdate;
/*LN-166*/         globalRisk = globalActivityScore;
/*LN-167*/     }
/*LN-168*/ 
/*LN-169*/     receive() external payable {}
/*LN-170*/ }
/*LN-171*/ 