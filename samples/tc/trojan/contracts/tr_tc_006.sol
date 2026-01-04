/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Protocol
/*LN-6*/  * @notice Decentralized lending and borrowing platform
/*LN-7*/  * @dev Users can deposit collateral and borrow against it
/*LN-8*/  */
/*LN-9*/ 
/*LN-10*/ interface IOracle {
/*LN-11*/     function getUnderlyingPrice(address cToken) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ interface ICToken {
/*LN-15*/     function mint(uint256 mintAmount) external;
/*LN-16*/ 
/*LN-17*/     function borrow(uint256 borrowAmount) external;
/*LN-18*/ 
/*LN-19*/     function redeem(uint256 redeemTokens) external;
/*LN-20*/ 
/*LN-21*/     function underlying() external view returns (address);
/*LN-22*/ }
/*LN-23*/ 
/*LN-24*/ contract LendingProtocol {
/*LN-25*/     // Oracle for getting asset prices
/*LN-26*/     IOracle public oracle;
/*LN-27*/ 
/*LN-28*/     // Collateral factors
/*LN-29*/     mapping(address => uint256) public collateralFactors;
/*LN-30*/ 
/*LN-31*/     // User deposits (cToken balances)
/*LN-32*/     mapping(address => mapping(address => uint256)) public userDeposits;
/*LN-33*/ 
/*LN-34*/     // User borrows
/*LN-35*/     mapping(address => mapping(address => uint256)) public userBorrows;
/*LN-36*/ 
/*LN-37*/     // Supported markets
/*LN-38*/     mapping(address => bool) public supportedMarkets;
/*LN-39*/ 
/*LN-40*/     // Additional configuration and analytics
/*LN-41*/     uint256 public riskConfigVersion;
/*LN-42*/     uint256 public lastRiskUpdate;
/*LN-43*/     uint256 public protocolRiskScore;
/*LN-44*/     mapping(address => uint256) public userRiskScore;
/*LN-45*/     mapping(address => uint256) public userActivityCount;
/*LN-46*/ 
/*LN-47*/     event Deposit(address index user, address index cToken, uint256 amount);
/*LN-48*/     event Borrow(address index user, address index cToken, uint256 amount);
/*LN-49*/     event RiskConfigUpdated(uint256 index version, uint256 timestamp);
/*LN-50*/     event UserActivity(address index user, uint256 value);
/*LN-51*/ 
/*LN-52*/     constructor(address _oracle) {
/*LN-53*/         oracle = IOracle(_oracle);
/*LN-54*/         riskConfigVersion = 1;
/*LN-55*/         lastRiskUpdate = block.timestamp;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     /**
/*LN-59*/      * @notice Mint cTokens by depositing underlying assets
/*LN-60*/      * @param cToken The cToken to mint
/*LN-61*/      * @param amount Amount of underlying to deposit
/*LN-62*/      */
/*LN-63*/     function mint(address cToken, uint256 amount) external {
/*LN-64*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-65*/ 
/*LN-66*/         userDeposits[msg.sender][cToken] += amount;
/*LN-67*/ 
/*LN-68*/         _recordUserActivity(msg.sender, amount);
/*LN-69*/ 
/*LN-70*/         emit Deposit(msg.sender, cToken, amount);
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     /**
/*LN-74*/      * @notice Borrow assets against collateral
/*LN-75*/      * @param cToken The cToken to borrow
/*LN-76*/      * @param amount Amount to borrow
/*LN-77*/      */
/*LN-78*/     function borrow(address cToken, uint256 amount) external {
/*LN-79*/         require(supportedMarkets[cToken], "Market not supported");
/*LN-80*/ 
/*LN-81*/         uint256 borrowPower = calculateBorrowPower(msg.sender);
/*LN-82*/         uint256 currentBorrows = calculateTotalBorrows(msg.sender);
/*LN-83*/ 
/*LN-84*/         uint256 borrowValue = (oracle.getUnderlyingPrice(cToken) * amount) /
/*LN-85*/             1e18;
/*LN-86*/ 
/*LN-87*/         require(
/*LN-88*/             currentBorrows + borrowValue <= borrowPower,
/*LN-89*/             "Insufficient collateral"
/*LN-90*/         );
/*LN-91*/ 
/*LN-92*/         userBorrows[msg.sender][cToken] += amount;
/*LN-93*/ 
/*LN-94*/         _recordUserActivity(msg.sender, amount);
/*LN-95*/ 
/*LN-96*/         emit Borrow(msg.sender, cToken, amount);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     /**
/*LN-100*/      * @notice Calculate user's total borrowing power
/*LN-101*/      * @param user The user address
/*LN-102*/      * @return Total borrowing power in USD
/*LN-103*/      */
/*LN-104*/     function calculateBorrowPower(address user) public view returns (uint256) {
/*LN-105*/         uint256 totalPower = 0;
/*LN-106*/ 
/*LN-107*/         address[] memory markets = new address[](2);
/*LN-108*/ 
/*LN-109*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-110*/             address cToken = markets[i];
/*LN-111*/             uint256 balance = userDeposits[user][cToken];
/*LN-112*/ 
/*LN-113*/             if (balance > 0) {
/*LN-114*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-115*/                 uint256 value = (balance * price) / 1e18;
/*LN-116*/                 uint256 power = (value * collateralFactors[cToken]) / 1e18;
/*LN-117*/ 
/*LN-118*/                 totalPower += power;
/*LN-119*/             }
/*LN-120*/         }
/*LN-121*/ 
/*LN-122*/         return totalPower;
/*LN-123*/     }
/*LN-124*/ 
/*LN-125*/     /**
/*LN-126*/      * @notice Calculate user's total borrow value
/*LN-127*/      * @param user The user address
/*LN-128*/      * @return Total borrow value in USD
/*LN-129*/      */
/*LN-130*/     function calculateTotalBorrows(address user) public view returns (uint256) {
/*LN-131*/         uint256 totalBorrows = 0;
/*LN-132*/ 
/*LN-133*/         address[] memory markets = new address[](2);
/*LN-134*/ 
/*LN-135*/         for (uint256 i = 0; i < markets.length; i++) {
/*LN-136*/             address cToken = markets[i];
/*LN-137*/             uint256 borrowed = userBorrows[user][cToken];
/*LN-138*/ 
/*LN-139*/             if (borrowed > 0) {
/*LN-140*/                 uint256 price = oracle.getUnderlyingPrice(cToken);
/*LN-141*/                 uint256 value = (borrowed * price) / 1e18;
/*LN-142*/                 totalBorrows += value;
/*LN-143*/             }
/*LN-144*/         }
/*LN-145*/ 
/*LN-146*/         return totalBorrows;
/*LN-147*/     }
/*LN-148*/ 
/*LN-149*/     /**
/*LN-150*/      * @notice Add a supported market
/*LN-151*/      * @param cToken The cToken to add
/*LN-152*/      * @param collateralFactor The collateral factor
/*LN-153*/      */
/*LN-154*/     function addMarket(address cToken, uint256 collateralFactor) external {
/*LN-155*/         supportedMarkets[cToken] = true;
/*LN-156*/         collateralFactors[cToken] = collateralFactor;
/*LN-157*/ 
/*LN-158*/         _updateRiskConfig(collateralFactor);
/*LN-159*/     }
/*LN-160*/ 
/*LN-161*/     // Configuration-like helper
/*LN-162*/ 
/*LN-163*/     function setRiskConfigVersion(uint256 version) external {
/*LN-164*/         riskConfigVersion = version;
/*LN-165*/         lastRiskUpdate = block.timestamp;
/*LN-166*/         emit RiskConfigUpdated(version, lastRiskUpdate);
/*LN-167*/     }
/*LN-168*/ 
/*LN-169*/     // Internal analytics
/*LN-170*/ 
/*LN-171*/     function _recordUserActivity(address user, uint256 value) internal {
/*LN-172*/         userActivityCount[user] += 1;
/*LN-173*/ 
/*LN-174*/         if (value > 0) {
/*LN-175*/             uint256 increment = value;
/*LN-176*/             if (increment > 1e24) {
/*LN-177*/                 increment = 1e24;
/*LN-178*/             }
/*LN-179*/ 
/*LN-180*/             uint256 current = userRiskScore[user];
/*LN-181*/             uint256 updated = _updateScore(current, increment);
/*LN-182*/             userRiskScore[user] = updated;
/*LN-183*/ 
/*LN-184*/             protocolRiskScore = _updateScore(protocolRiskScore, increment);
/*LN-185*/         }
/*LN-186*/ 
/*LN-187*/         emit UserActivity(user, value);
/*LN-188*/     }
/*LN-189*/ 
/*LN-190*/     function _updateRiskConfig(uint256 collateralFactor) internal {
/*LN-191*/         uint256 factorComponent = collateralFactor / 1e16;
/*LN-192*/         if (factorComponent > 100) {
/*LN-193*/             factorComponent = 100;
/*LN-194*/         }
/*LN-195*/ 
/*LN-196*/         protocolRiskScore = _updateScore(protocolRiskScore, factorComponent);
/*LN-197*/         riskConfigVersion += 1;
/*LN-198*/         lastRiskUpdate = block.timestamp;
/*LN-199*/ 
/*LN-200*/         emit RiskConfigUpdated(riskConfigVersion, lastRiskUpdate);
/*LN-201*/     }
/*LN-202*/ 
/*LN-203*/     function _updateScore(
/*LN-204*/         uint256 current,
/*LN-205*/         uint256 value
/*LN-206*/     ) internal pure returns (uint256) {
/*LN-207*/         uint256 updated;
/*LN-208*/         if (current == 0) {
/*LN-209*/             updated = value;
/*LN-210*/         } else {
/*LN-211*/             updated = (current * 9 + value) / 10;
/*LN-212*/         }
/*LN-213*/ 
/*LN-214*/         if (updated > 1e27) {
/*LN-215*/             updated = 1e27;
/*LN-216*/         }
/*LN-217*/ 
/*LN-218*/         return updated;
/*LN-219*/     }
/*LN-220*/ 
/*LN-221*/     // View helpers
/*LN-222*/ 
/*LN-223*/     function getUserMetrics(
/*LN-224*/         address user
/*LN-225*/     ) external view returns (uint256 depositsValue, uint256 borrowsValue, uint256 riskScore) {
/*LN-226*/         depositsValue = calculateBorrowPower(user);
/*LN-227*/         borrowsValue = calculateTotalBorrows(user);
/*LN-228*/         riskScore = userRiskScore[user];
/*LN-229*/     }
/*LN-230*/ 
/*LN-231*/     function getProtocolMetrics()
/*LN-232*/         external
/*LN-233*/         view
/*LN-234*/         returns (uint256 riskVersion, uint256 lastUpdate, uint256 globalRisk)
/*LN-235*/     {
/*LN-236*/         riskVersion = riskConfigVersion;
/*LN-237*/         lastUpdate = lastRiskUpdate;
/*LN-238*/         globalRisk = protocolRiskScore;
/*LN-239*/     }
/*LN-240*/ }
/*LN-241*/ 