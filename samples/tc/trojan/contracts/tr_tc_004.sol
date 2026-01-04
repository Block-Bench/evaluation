/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Automated Market Maker Pool
/*LN-6*/  * @notice Liquidity pool for token swaps with concentrated liquidity
/*LN-7*/  * @dev Allows users to add liquidity and perform token swaps
/*LN-8*/  */
/*LN-9*/ contract AMMPool {
/*LN-10*/     // Token balances in the pool
/*LN-11*/     mapping(uint256 => uint256) public balances; // 0 = token0, 1 = token1
/*LN-12*/ 
/*LN-13*/     // LP token
/*LN-14*/     mapping(address => uint256) public lpBalances;
/*LN-15*/     uint256 public totalLPSupply;
/*LN-16*/ 
/*LN-17*/     // Reentrancy guard (state-style, not used as a modifier)
/*LN-18*/     uint256 private _status;
/*LN-19*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-20*/     uint256 private constant _ENTERED = 2;
/*LN-21*/ 
/*LN-22*/     // Additional metrics and configuration
/*LN-23*/     uint256 public poolActivityScore;
/*LN-24*/     uint256 public lastLiquidityBlock;
/*LN-25*/     uint256 public configVersion;
/*LN-26*/     mapping(address => uint256) public userInteractionCount;
/*LN-27*/ 
/*LN-28*/     event LiquidityAdded(
/*LN-29*/         address indexed provider,
/*LN-30*/         uint256[2] amounts,
/*LN-31*/         uint256 lpMinted
/*LN-32*/     );
/*LN-33*/     event LiquidityRemoved(
/*LN-34*/         address indexed provider,
/*LN-35*/         uint256 lpBurned,
/*LN-36*/         uint256[2] amounts
/*LN-37*/     );
/*LN-38*/     event PoolConfigured(uint256 indexed version, uint256 timestamp);
/*LN-39*/     event PoolActivity(address indexed user, uint256 value);
/*LN-40*/ 
/*LN-41*/     constructor() {
/*LN-42*/         _status = _NOT_ENTERED;
/*LN-43*/         configVersion = 1;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Add liquidity to the pool
/*LN-48*/      * @param amounts Array of token amounts to deposit
/*LN-49*/      * @param min_mint_amount Minimum LP tokens to mint
/*LN-50*/      * @return Amount of LP tokens minted
/*LN-51*/      */
/*LN-52*/     function add_liquidity(
/*LN-53*/         uint256[2] memory amounts,
/*LN-54*/         uint256 min_mint_amount
/*LN-55*/     ) external payable returns (uint256) {
/*LN-56*/         require(amounts[0] == msg.value, "ETH amount mismatch");
/*LN-57*/ 
/*LN-58*/         uint256 lpToMint;
/*LN-59*/         if (totalLPSupply == 0) {
/*LN-60*/             lpToMint = amounts[0] + amounts[1];
/*LN-61*/         } else {
/*LN-62*/             uint256 totalValue = balances[0] + balances[1];
/*LN-63*/             lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
/*LN-64*/         }
/*LN-65*/ 
/*LN-66*/         require(lpToMint >= min_mint_amount, "Slippage");
/*LN-67*/ 
/*LN-68*/         balances[0] += amounts[0];
/*LN-69*/         balances[1] += amounts[1];
/*LN-70*/ 
/*LN-71*/         lpBalances[msg.sender] += lpToMint;
/*LN-72*/         totalLPSupply += lpToMint;
/*LN-73*/ 
/*LN-74*/         if (amounts[0] > 0) {
/*LN-75*/             _handleETHTransfer(amounts[0]);
/*LN-76*/         }
/*LN-77*/ 
/*LN-78*/         lastLiquidityBlock = block.number;
/*LN-79*/         _recordPoolActivity(msg.sender, amounts[0] + amounts[1]);
/*LN-80*/ 
/*LN-81*/         emit LiquidityAdded(msg.sender, amounts, lpToMint);
/*LN-82*/         return lpToMint;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     /**
/*LN-86*/      * @notice Remove liquidity from the pool
/*LN-87*/      * @param lpAmount Amount of LP tokens to burn
/*LN-88*/      * @param min_amounts Minimum amounts to receive
/*LN-89*/      */
/*LN-90*/     function remove_liquidity(
/*LN-91*/         uint256 lpAmount,
/*LN-92*/         uint256[2] memory min_amounts
/*LN-93*/     ) external {
/*LN-94*/         require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");
/*LN-95*/ 
/*LN-96*/         uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
/*LN-97*/         uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;
/*LN-98*/ 
/*LN-99*/         require(
/*LN-100*/             amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
/*LN-101*/             "Slippage"
/*LN-102*/         );
/*LN-103*/ 
/*LN-104*/         lpBalances[msg.sender] -= lpAmount;
/*LN-105*/         totalLPSupply -= lpAmount;
/*LN-106*/ 
/*LN-107*/         balances[0] -= amount0;
/*LN-108*/         balances[1] -= amount1;
/*LN-109*/ 
/*LN-110*/         if (amount0 > 0) {
/*LN-111*/             payable(msg.sender).transfer(amount0);
/*LN-112*/         }
/*LN-113*/ 
/*LN-114*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-115*/         _recordPoolActivity(msg.sender, amount0 + amount1);
/*LN-116*/ 
/*LN-117*/         emit LiquidityRemoved(msg.sender, lpAmount, amounts);
/*LN-118*/     }
/*LN-119*/ 
/*LN-120*/     /**
/*LN-121*/      * @notice Internal function for ETH operations
/*LN-122*/      */
/*LN-123*/     function _handleETHTransfer(uint256 amount) internal {
/*LN-124*/         (bool success, ) = msg.sender.call{value: 0}("");
/*LN-125*/         require(success, "Transfer failed");
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     /**
/*LN-129*/      * @notice Exchange tokens
/*LN-130*/      * @param i Index of input token
/*LN-131*/      * @param j Index of output token
/*LN-132*/      * @param dx Input amount
/*LN-133*/      * @param min_dy Minimum output amount
/*LN-134*/      * @return Output amount
/*LN-135*/      */
/*LN-136*/     function exchange(
/*LN-137*/         int128 i,
/*LN-138*/         int128 j,
/*LN-139*/         uint256 dx,
/*LN-140*/         uint256 min_dy
/*LN-141*/     ) external payable returns (uint256) {
/*LN-142*/         uint256 ui = uint256(int256(i));
/*LN-143*/         uint256 uj = uint256(int256(j));
/*LN-144*/ 
/*LN-145*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-146*/ 
/*LN-147*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-148*/         require(dy >= min_dy, "Slippage");
/*LN-149*/ 
/*LN-150*/         if (ui == 0) {
/*LN-151*/             require(msg.value == dx, "ETH mismatch");
/*LN-152*/             balances[0] += dx;
/*LN-153*/         }
/*LN-154*/ 
/*LN-155*/         balances[ui] += dx;
/*LN-156*/         balances[uj] -= dy;
/*LN-157*/ 
/*LN-158*/         if (uj == 0) {
/*LN-159*/             payable(msg.sender).transfer(dy);
/*LN-160*/         }
/*LN-161*/ 
/*LN-162*/         _recordPoolActivity(msg.sender, dx);
/*LN-163*/ 
/*LN-164*/         return dy;
/*LN-165*/     }
/*LN-166*/ 
/*LN-167*/     // Configuration-like helpers
/*LN-168*/ 
/*LN-169*/     function setConfigVersion(uint256 version) external {
/*LN-170*/         configVersion = version;
/*LN-171*/         emit PoolConfigured(version, block.timestamp);
/*LN-172*/     }
/*LN-173*/ 
/*LN-174*/     function simulateExchange(
/*LN-175*/         int128 i,
/*LN-176*/         int128 j,
/*LN-177*/         uint256 dx
/*LN-178*/     ) external view returns (uint256) {
/*LN-179*/         uint256 ui = uint256(int256(i));
/*LN-180*/         uint256 uj = uint256(int256(j));
/*LN-181*/ 
/*LN-182*/         if (ui >= 2 || uj >= 2 || ui == uj) {
/*LN-183*/             return 0;
/*LN-184*/         }
/*LN-185*/ 
/*LN-186*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-187*/         return dy;
/*LN-188*/     }
/*LN-189*/ 
/*LN-190*/     // Internal analytics
/*LN-191*/ 
/*LN-192*/     function _recordPoolActivity(address user, uint256 value) internal {
/*LN-193*/         userInteractionCount[user] += 1;
/*LN-194*/         uint256 increment = value;
/*LN-195*/         if (increment > 0) {
/*LN-196*/             if (increment > 1e24) {
/*LN-197*/                 increment = 1e24;
/*LN-198*/             }
/*LN-199*/             poolActivityScore += increment;
/*LN-200*/         }
/*LN-201*/         if (poolActivityScore > 1e27) {
/*LN-202*/             poolActivityScore = 1e27;
/*LN-203*/         }
/*LN-204*/         lastLiquidityBlock = block.number;
/*LN-205*/         emit PoolActivity(user, value);
/*LN-206*/     }
/*LN-207*/ 
/*LN-208*/     // View helpers
/*LN-209*/ 
/*LN-210*/     function getUserMetrics(address user)
/*LN-211*/         external
/*LN-212*/         view
/*LN-213*/         returns (uint256 lpBalance, uint256 interactions)
/*LN-214*/     {
/*LN-215*/         lpBalance = lpBalances[user];
/*LN-216*/         interactions = userInteractionCount[user];
/*LN-217*/     }
/*LN-218*/ 
/*LN-219*/     function getPoolMetrics()
/*LN-220*/         external
/*LN-221*/         view
/*LN-222*/         returns (uint256 token0, uint256 token1, uint256 activity, uint256 version)
/*LN-223*/     {
/*LN-224*/         token0 = balances[0];
/*LN-225*/         token1 = balances[1];
/*LN-226*/         activity = poolActivityScore;
/*LN-227*/         version = configVersion;
/*LN-228*/     }
/*LN-229*/ 
/*LN-230*/     receive() external payable {}
/*LN-231*/ }
/*LN-232*/ 