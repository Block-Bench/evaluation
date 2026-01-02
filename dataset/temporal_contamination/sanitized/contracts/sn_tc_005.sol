/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ contract StablePool {
/*LN-5*/     // Token balances in the pool
/*LN-6*/     mapping(uint256 => uint256) public balances; // 0 = ETH, 1 = pETH
/*LN-7*/ 
/*LN-8*/     // LP token
/*LN-9*/     mapping(address => uint256) public lpBalances;
/*LN-10*/     uint256 public totalLPSupply;
/*LN-11*/ 
/*LN-12*/     uint256 private _status;
/*LN-13*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-14*/     uint256 private constant _ENTERED = 2;
/*LN-15*/ 
/*LN-16*/     event LiquidityAdded(
/*LN-17*/         address indexed provider,
/*LN-18*/         uint256[2] amounts,
/*LN-19*/         uint256 lpMinted
/*LN-20*/     );
/*LN-21*/     event LiquidityRemoved(
/*LN-22*/         address indexed provider,
/*LN-23*/         uint256 lpBurned,
/*LN-24*/         uint256[2] amounts
/*LN-25*/     );
/*LN-26*/ 
/*LN-27*/     constructor() {
/*LN-28*/         _status = _NOT_ENTERED;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     function add_liquidity(
/*LN-32*/         uint256[2] memory amounts,
/*LN-33*/         uint256 min_mint_amount
/*LN-34*/     ) external payable returns (uint256) {
/*LN-35*/ 
/*LN-36*/         require(amounts[0] == msg.value, "ETH amount mismatch");
/*LN-37*/ 
/*LN-38*/         // Calculate LP tokens to mint
/*LN-39*/         uint256 lpToMint;
/*LN-40*/         if (totalLPSupply == 0) {
/*LN-41*/             lpToMint = amounts[0] + amounts[1];
/*LN-42*/         } else {
/*LN-43*/             // Simplified: real formula is more complex
/*LN-44*/             uint256 totalValue = balances[0] + balances[1];
/*LN-45*/             lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
/*LN-46*/         }
/*LN-47*/ 
/*LN-48*/         require(lpToMint >= min_mint_amount, "Slippage");
/*LN-49*/ 
/*LN-50*/         balances[0] += amounts[0];
/*LN-51*/         balances[1] += amounts[1];
/*LN-52*/ 
/*LN-53*/         // Mint LP tokens
/*LN-54*/         lpBalances[msg.sender] += lpToMint;
/*LN-55*/         totalLPSupply += lpToMint;
/*LN-56*/ 
/*LN-57*/         if (amounts[0] > 0) {
/*LN-58*/             // Simulate pool's internal operations that involve ETH transfer
/*LN-59*/ 
/*LN-60*/             _handleETHTransfer(amounts[0]);
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         emit LiquidityAdded(msg.sender, amounts, lpToMint);
/*LN-64*/         return lpToMint;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     /**
/*LN-68*/      * @notice Remove liquidity from the pool
/*LN-69*/      * @param lpAmount Amount of LP tokens to burn
/*LN-70*/      * @param min_amounts Minimum amounts to receive [ETH, pETH]
/*LN-71*/      */
/*LN-72*/     function remove_liquidity(
/*LN-73*/         uint256 lpAmount,
/*LN-74*/         uint256[2] memory min_amounts
/*LN-75*/     ) external {
/*LN-76*/         require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");
/*LN-77*/ 
/*LN-78*/         // Calculate amounts to return
/*LN-79*/         uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
/*LN-80*/         uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;
/*LN-81*/ 
/*LN-82*/         require(
/*LN-83*/             amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
/*LN-84*/             "Slippage"
/*LN-85*/         );
/*LN-86*/ 
/*LN-87*/         // Burn LP tokens
/*LN-88*/         lpBalances[msg.sender] -= lpAmount;
/*LN-89*/         totalLPSupply -= lpAmount;
/*LN-90*/ 
/*LN-91*/         // Update balances
/*LN-92*/         balances[0] -= amount0;
/*LN-93*/         balances[1] -= amount1;
/*LN-94*/ 
/*LN-95*/         // Transfer tokens
/*LN-96*/         if (amount0 > 0) {
/*LN-97*/             payable(msg.sender).transfer(amount0);
/*LN-98*/         }
/*LN-99*/ 
/*LN-100*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-101*/         emit LiquidityRemoved(msg.sender, lpAmount, amounts);
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     function _handleETHTransfer(uint256 amount) internal {
/*LN-105*/ 
/*LN-106*/         // Simulate operations that trigger external call
/*LN-107*/ 
/*LN-108*/         (bool success, ) = msg.sender.call{value: 0}("");
/*LN-109*/         require(success, "Transfer failed");
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/     /**
/*LN-113*/      * @notice Exchange tokens (simplified)
/*LN-114*/      * @param i Index of input token
/*LN-115*/      * @param j Index of output token
/*LN-116*/      * @param dx Input amount
/*LN-117*/      * @param min_dy Minimum output amount
/*LN-118*/      */
/*LN-119*/     function exchange(
/*LN-120*/         int128 i,
/*LN-121*/         int128 j,
/*LN-122*/         uint256 dx,
/*LN-123*/         uint256 min_dy
/*LN-124*/     ) external payable returns (uint256) {
/*LN-125*/         uint256 ui = uint256(int256(i));
/*LN-126*/         uint256 uj = uint256(int256(j));
/*LN-127*/ 
/*LN-128*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-129*/ 
/*LN-130*/         // Simplified exchange logic
/*LN-131*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-132*/         require(dy >= min_dy, "Slippage");
/*LN-133*/ 
/*LN-134*/         if (ui == 0) {
/*LN-135*/             require(msg.value == dx, "ETH mismatch");
/*LN-136*/             balances[0] += dx;
/*LN-137*/         }
/*LN-138*/ 
/*LN-139*/         balances[ui] += dx;
/*LN-140*/         balances[uj] -= dy;
/*LN-141*/ 
/*LN-142*/         if (uj == 0) {
/*LN-143*/             payable(msg.sender).transfer(dy);
/*LN-144*/         }
/*LN-145*/ 
/*LN-146*/         return dy;
/*LN-147*/     }
/*LN-148*/ 
/*LN-149*/     receive() external payable {
/*LN-150*/     }
/*LN-151*/ }
/*LN-152*/ 