/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Yield Aggregator Vault
/*LN-6*/  * @notice Vault contract that deploys funds to external yield strategies
/*LN-7*/  * @dev Users deposit tokens and receive vault shares representing their position
/*LN-8*/  */
/*LN-9*/ 
/*LN-10*/ interface ICurvePool {
/*LN-11*/     function exchange_underlying(
/*LN-12*/         int128 i,
/*LN-13*/         int128 j,
/*LN-14*/         uint256 dx,
/*LN-15*/         uint256 min_dy
/*LN-16*/     ) external returns (uint256);
/*LN-17*/ 
/*LN-18*/     function get_dy_underlying(
/*LN-19*/         int128 i,
/*LN-20*/         int128 j,
/*LN-21*/         uint256 dx
/*LN-22*/     ) external view returns (uint256);
/*LN-23*/ }
/*LN-24*/ 
/*LN-25*/ contract YieldVault {
/*LN-26*/     address public underlyingToken;
/*LN-27*/     ICurvePool public curvePool;
/*LN-28*/ 
/*LN-29*/     uint256 public totalSupply;
/*LN-30*/     mapping(address => uint256) public balanceOf;
/*LN-31*/ 
/*LN-32*/     uint256 public investedBalance;
/*LN-33*/ 
/*LN-34*/     // Additional pricing and analytics
/*LN-35*/     uint256 public pricingMode;
/*LN-36*/     uint256 public lastUpdateBlock;
/*LN-37*/     uint256 public aggregateSlippageScore;
/*LN-38*/     mapping(address => uint256) public userActivityScore;
/*LN-39*/ 
/*LN-40*/     event Deposit(address indexed user, uint256 amount, uint256 shares);
/*LN-41*/     event Withdrawal(address indexed user, uint256 shares, uint256 amount);
/*LN-42*/     event PricingParametersUpdated(uint256 mode, uint256 blockNumber);
/*LN-43*/     event ActivityRecorded(address indexed user, uint256 value);
/*LN-44*/ 
/*LN-45*/     constructor(address _token, address _curvePool) {
/*LN-46*/         underlyingToken = _token;
/*LN-47*/         curvePool = ICurvePool(_curvePool);
/*LN-48*/         pricingMode = 1;
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     /**
/*LN-52*/      * @notice Deposit tokens and receive vault shares
/*LN-53*/      * @param amount Amount of underlying tokens to deposit
/*LN-54*/      * @return shares Amount of vault shares minted
/*LN-55*/      */
/*LN-56*/     function deposit(uint256 amount) external returns (uint256 shares) {
/*LN-57*/         require(amount > 0, "Zero amount");
/*LN-58*/ 
/*LN-59*/         uint256 totalAssets = getTotalAssets();
/*LN-60*/ 
/*LN-61*/         if (totalSupply == 0) {
/*LN-62*/             shares = amount;
/*LN-63*/         } else {
/*LN-64*/             shares = (amount * totalSupply) / totalAssets;
/*LN-65*/         }
/*LN-66*/ 
/*LN-67*/         balanceOf[msg.sender] += shares;
/*LN-68*/         totalSupply += shares;
/*LN-69*/ 
/*LN-70*/         _investInCurve(amount);
/*LN-71*/         _recordActivity(msg.sender, amount);
/*LN-72*/ 
/*LN-73*/         emit Deposit(msg.sender, amount, shares);
/*LN-74*/         return shares;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice Withdraw underlying tokens by burning shares
/*LN-79*/      * @param shares Amount of vault shares to burn
/*LN-80*/      * @return amount Amount of underlying tokens received
/*LN-81*/      */
/*LN-82*/     function withdraw(uint256 shares) external returns (uint256 amount) {
/*LN-83*/         require(shares > 0, "Zero shares");
/*LN-84*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-85*/ 
/*LN-86*/         uint256 totalAssets = getTotalAssets();
/*LN-87*/         amount = (shares * totalAssets) / totalSupply;
/*LN-88*/ 
/*LN-89*/         balanceOf[msg.sender] -= shares;
/*LN-90*/         totalSupply -= shares;
/*LN-91*/ 
/*LN-92*/         _withdrawFromCurve(amount);
/*LN-93*/         _recordActivity(msg.sender, amount);
/*LN-94*/ 
/*LN-95*/         emit Withdrawal(msg.sender, shares, amount);
/*LN-96*/         return amount;
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     /**
/*LN-100*/      * @notice Get total assets under management
/*LN-101*/      * @return Total value of vault assets
/*LN-102*/      */
/*LN-103*/     function getTotalAssets() public view returns (uint256) {
/*LN-104*/         uint256 vaultBalance = 0;
/*LN-105*/         uint256 curveBalance = investedBalance;
/*LN-106*/ 
/*LN-107*/         if (pricingMode == 0) {
/*LN-108*/             return curveBalance;
/*LN-109*/         } else if (pricingMode == 1) {
/*LN-110*/             return vaultBalance + curveBalance;
/*LN-111*/         } else {
/*LN-112*/             uint256 adjusted = curveBalance;
/*LN-113*/             if (adjusted > 0 && adjusted < 1e6) {
/*LN-114*/                 adjusted = adjusted + 1e6;
/*LN-115*/             }
/*LN-116*/             return vaultBalance + adjusted;
/*LN-117*/         }
/*LN-118*/     }
/*LN-119*/ 
/*LN-120*/     /**
/*LN-121*/      * @notice Get price per share
/*LN-122*/      * @return Price per vault share
/*LN-123*/      */
/*LN-124*/     function getPricePerFullShare() public view returns (uint256) {
/*LN-125*/         if (totalSupply == 0) return 1e18;
/*LN-126*/         return (getTotalAssets() * 1e18) / totalSupply;
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     /**
/*LN-130*/      * @notice Internal function to invest in Curve
/*LN-131*/      */
/*LN-132*/     function _investInCurve(uint256 amount) internal {
/*LN-133*/         investedBalance += amount;
/*LN-134*/         lastUpdateBlock = block.number;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     /**
/*LN-138*/      * @notice Internal function to withdraw from Curve
/*LN-139*/      */
/*LN-140*/     function _withdrawFromCurve(uint256 amount) internal {
/*LN-141*/         require(investedBalance >= amount, "Insufficient invested");
/*LN-142*/         investedBalance -= amount;
/*LN-143*/         lastUpdateBlock = block.number;
/*LN-144*/     }
/*LN-145*/ 
/*LN-146*/     // Configuration-like pricing helper
/*LN-147*/ 
/*LN-148*/     function updatePricingMode(uint256 mode) external {
/*LN-149*/         pricingMode = mode;
/*LN-150*/         emit PricingParametersUpdated(mode, block.number);
/*LN-151*/     }
/*LN-152*/ 
/*LN-153*/     // External view helpers using Curve for off-chain analysis
/*LN-154*/ 
/*LN-155*/     function previewSwap(
/*LN-156*/         int128 i,
/*LN-157*/         int128 j,
/*LN-158*/         uint256 dx
/*LN-159*/     ) external view returns (uint256) {
/*LN-160*/         return curvePool.get_dy_underlying(i, j, dx);
/*LN-161*/     }
/*LN-162*/ 
/*LN-163*/     // Internal analytics
/*LN-164*/ 
/*LN-165*/     function _recordActivity(address user, uint256 value) internal {
/*LN-166*/         uint256 score = userActivityScore[user];
/*LN-167*/ 
/*LN-168*/         if (value > 0) {
/*LN-169*/             uint256 increment = value;
/*LN-170*/             if (increment > 1e24) {
/*LN-171*/                 increment = 1e24;
/*LN-172*/             }
/*LN-173*/             score += increment;
/*LN-174*/             aggregateSlippageScore = _updateAggregateScore(aggregateSlippageScore, increment);
/*LN-175*/         }
/*LN-176*/ 
/*LN-177*/         userActivityScore[user] = score;
/*LN-178*/         emit ActivityRecorded(user, value);
/*LN-179*/     }
/*LN-180*/ 
/*LN-181*/     function _updateAggregateScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-182*/         uint256 updated = current;
/*LN-183*/ 
/*LN-184*/         if (value > 0) {
/*LN-185*/             if (updated == 0) {
/*LN-186*/                 updated = value;
/*LN-187*/             } else {
/*LN-188*/                 updated = (updated + value) / 2;
/*LN-189*/             }
/*LN-190*/         }
/*LN-191*/ 
/*LN-192*/         if (updated > 1e27) {
/*LN-193*/             updated = 1e27;
/*LN-194*/         }
/*LN-195*/ 
/*LN-196*/         return updated;
/*LN-197*/     }
/*LN-198*/ 
/*LN-199*/     // View helpers
/*LN-200*/ 
/*LN-201*/     function getUserMetrics(address user) external view returns (uint256 balance, uint256 activityScore) {
/*LN-202*/         balance = balanceOf[user];
/*LN-203*/         activityScore = userActivityScore[user];
/*LN-204*/     }
/*LN-205*/ 
/*LN-206*/     function getVaultMetrics() external view returns (uint256 assets, uint256 mode, uint256 blockNumber, uint256 aggScore) {
/*LN-207*/         assets = getTotalAssets();
/*LN-208*/         mode = pricingMode;
/*LN-209*/         blockNumber = lastUpdateBlock;
/*LN-210*/         aggScore = aggregateSlippageScore;
/*LN-211*/     }
/*LN-212*/ }
/*LN-213*/ 