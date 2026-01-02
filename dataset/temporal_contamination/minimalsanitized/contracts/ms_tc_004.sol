/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface ICurvePool {
/*LN-5*/     function exchange_underlying(
/*LN-6*/         int128 i,
/*LN-7*/         int128 j,
/*LN-8*/         uint256 dx,
/*LN-9*/         uint256 min_dy
/*LN-10*/     ) external returns (uint256);
/*LN-11*/ 
/*LN-12*/     function get_dy_underlying(
/*LN-13*/         int128 i,
/*LN-14*/         int128 j,
/*LN-15*/         uint256 dx
/*LN-16*/     ) external view returns (uint256);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ contract HarvestVault {
/*LN-20*/     address public underlyingToken; // e.g., USDC
/*LN-21*/     ICurvePool public curvePool;
/*LN-22*/ 
/*LN-23*/     uint256 public totalSupply; // Total fUSDC shares
/*LN-24*/     mapping(address => uint256) public balanceOf;
/*LN-25*/ 
/*LN-26*/     // This tracks assets that are "working" in external protocols
/*LN-27*/     uint256 public investedBalance;
/*LN-28*/ 
/*LN-29*/     event Deposit(address indexed user, uint256 amount, uint256 shares);
/*LN-30*/     event Withdrawal(address indexed user, uint256 shares, uint256 amount);
/*LN-31*/ 
/*LN-32*/     constructor(address _token, address _curvePool) {
/*LN-33*/         underlyingToken = _token;
/*LN-34*/         curvePool = ICurvePool(_curvePool);
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function deposit(uint256 amount) external returns (uint256 shares) {
/*LN-38*/         require(amount > 0, "Zero amount");
/*LN-39*/ 
/*LN-40*/         // Transfer tokens from user
/*LN-41*/         // IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);
/*LN-42*/ 
/*LN-43*/         // Calculate shares based on current price
/*LN-44*/         if (totalSupply == 0) {
/*LN-45*/             shares = amount;
/*LN-46*/         } else {
/*LN-47*/             // shares = amount * totalSupply / totalAssets()
/*LN-48*/            
/*LN-49*/             
/*LN-50*/             uint256 totalAssets = getTotalAssets();
/*LN-51*/             shares = (amount * totalSupply) / totalAssets;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         balanceOf[msg.sender] += shares;
/*LN-55*/         totalSupply += shares;
/*LN-56*/ 
/*LN-57*/         // Strategy: Deploy funds to Curve for yield
/*LN-58*/         _investInCurve(amount);
/*LN-59*/ 
/*LN-60*/         emit Deposit(msg.sender, amount, shares);
/*LN-61*/         return shares;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     function withdraw(uint256 shares) external returns (uint256 amount) {
/*LN-65*/         require(shares > 0, "Zero shares");
/*LN-66*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-67*/ 
/*LN-68*/         // Calculate amount based on current price
/*LN-69*/         uint256 totalAssets = getTotalAssets();
/*LN-70*/         amount = (shares * totalAssets) / totalSupply;
/*LN-71*/ 
/*LN-72*/         balanceOf[msg.sender] -= shares;
/*LN-73*/         totalSupply -= shares;
/*LN-74*/ 
/*LN-75*/         // Withdraw from Curve strategy if needed
/*LN-76*/         _withdrawFromCurve(amount);
/*LN-77*/ 
/*LN-78*/         // Transfer tokens to user
/*LN-79*/         // IERC20(underlyingToken).transfer(msg.sender, amount);
/*LN-80*/ 
/*LN-81*/         emit Withdrawal(msg.sender, shares, amount);
/*LN-82*/         return amount;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     function getTotalAssets() public view returns (uint256) {
/*LN-86*/         // Assets in vault + assets in Curve
/*LN-87*/         
/*LN-88*/         
/*LN-89*/ 
/*LN-90*/         uint256 vaultBalance = 0; // IERC20(underlyingToken).balanceOf(address(this));
/*LN-91*/         uint256 curveBalance = investedBalance;
/*LN-92*/ 
/*LN-93*/         // the Curve pool's exchange rates
/*LN-94*/         return vaultBalance + curveBalance;
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     function getPricePerFullShare() public view returns (uint256) {
/*LN-98*/         if (totalSupply == 0) return 1e18;
/*LN-99*/         return (getTotalAssets() * 1e18) / totalSupply;
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     /**
/*LN-103*/      * @notice Internal function to invest in Curve
/*LN-104*/      * @dev Simplified - in reality, Harvest used Curve pools for yield
/*LN-105*/      */
/*LN-106*/     function _investInCurve(uint256 amount) internal {
/*LN-107*/         investedBalance += amount;
/*LN-108*/ 
/*LN-109*/         // In reality, this would:
/*LN-110*/         // 1. Add liquidity to Curve pool
/*LN-111*/         // 2. Stake LP tokens
/*LN-112*/         // 3. Track the invested amount
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     /**
/*LN-116*/      * @notice Internal function to withdraw from Curve
/*LN-117*/      * @dev Simplified - in reality, would unstake and remove liquidity
/*LN-118*/      */
/*LN-119*/     function _withdrawFromCurve(uint256 amount) internal {
/*LN-120*/         require(investedBalance >= amount, "Insufficient invested");
/*LN-121*/         investedBalance -= amount;
/*LN-122*/ 
/*LN-123*/         // In reality, this would:
/*LN-124*/         // 1. Unstake LP tokens
/*LN-125*/         // 2. Remove liquidity from Curve
/*LN-126*/         // 3. Get underlying tokens back
/*LN-127*/     }
/*LN-128*/ }
/*LN-129*/ 