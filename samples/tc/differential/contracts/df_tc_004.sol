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
/*LN-17*/     // Reentrancy guard
/*LN-18*/     uint256 private _status;
/*LN-19*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-20*/     uint256 private constant _ENTERED = 2;
/*LN-21*/ 
/*LN-22*/     event LiquidityAdded(
/*LN-23*/         address indexed provider,
/*LN-24*/         uint256[2] amounts,
/*LN-25*/         uint256 lpMinted
/*LN-26*/     );
/*LN-27*/     event LiquidityRemoved(
/*LN-28*/         address indexed provider,
/*LN-29*/         uint256 lpBurned,
/*LN-30*/         uint256[2] amounts
/*LN-31*/     );
/*LN-32*/ 
/*LN-33*/     constructor() {
/*LN-34*/         _status = _NOT_ENTERED;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     /**
/*LN-38*/      * @notice Add liquidity to the pool
/*LN-39*/      * @param amounts Array of token amounts to deposit
/*LN-40*/      * @param min_mint_amount Minimum LP tokens to mint
/*LN-41*/      * @return Amount of LP tokens minted
/*LN-42*/      */
/*LN-43*/     function add_liquidity(
/*LN-44*/         uint256[2] memory amounts,
/*LN-45*/         uint256 min_mint_amount
/*LN-46*/     ) external payable returns (uint256) {
/*LN-47*/         require(_status != _ENTERED, "Reentrancy detected");
/*LN-48*/         _status = _ENTERED;
/*LN-49*/ 
/*LN-50*/         require(amounts[0] == msg.value, "ETH amount mismatch");
/*LN-51*/ 
/*LN-52*/         // Calculate LP tokens to mint
/*LN-53*/         uint256 lpToMint;
/*LN-54*/         if (totalLPSupply == 0) {
/*LN-55*/             lpToMint = amounts[0] + amounts[1];
/*LN-56*/         } else {
/*LN-57*/             uint256 totalValue = balances[0] + balances[1];
/*LN-58*/             lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
/*LN-59*/         }
/*LN-60*/ 
/*LN-61*/         require(lpToMint >= min_mint_amount, "Slippage");
/*LN-62*/ 
/*LN-63*/         // Update balances
/*LN-64*/         balances[0] += amounts[0];
/*LN-65*/         balances[1] += amounts[1];
/*LN-66*/ 
/*LN-67*/         // Mint LP tokens
/*LN-68*/         lpBalances[msg.sender] += lpToMint;
/*LN-69*/         totalLPSupply += lpToMint;
/*LN-70*/ 
/*LN-71*/         // Handle ETH operations
/*LN-72*/         if (amounts[0] > 0) {
/*LN-73*/             _handleETHTransfer(amounts[0]);
/*LN-74*/         }
/*LN-75*/ 
/*LN-76*/         _status = _NOT_ENTERED;
/*LN-77*/         emit LiquidityAdded(msg.sender, amounts, lpToMint);
/*LN-78*/         return lpToMint;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     /**
/*LN-82*/      * @notice Remove liquidity from the pool
/*LN-83*/      * @param lpAmount Amount of LP tokens to burn
/*LN-84*/      * @param min_amounts Minimum amounts to receive
/*LN-85*/      */
/*LN-86*/     function remove_liquidity(
/*LN-87*/         uint256 lpAmount,
/*LN-88*/         uint256[2] memory min_amounts
/*LN-89*/     ) external {
/*LN-90*/         require(_status != _ENTERED, "Reentrancy detected");
/*LN-91*/         _status = _ENTERED;
/*LN-92*/ 
/*LN-93*/         require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");
/*LN-94*/ 
/*LN-95*/         // Calculate amounts to return
/*LN-96*/         uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
/*LN-97*/         uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;
/*LN-98*/ 
/*LN-99*/         require(
/*LN-100*/             amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
/*LN-101*/             "Slippage"
/*LN-102*/         );
/*LN-103*/ 
/*LN-104*/         // Burn LP tokens
/*LN-105*/         lpBalances[msg.sender] -= lpAmount;
/*LN-106*/         totalLPSupply -= lpAmount;
/*LN-107*/ 
/*LN-108*/         // Update balances
/*LN-109*/         balances[0] -= amount0;
/*LN-110*/         balances[1] -= amount1;
/*LN-111*/ 
/*LN-112*/         // Transfer tokens
/*LN-113*/         if (amount0 > 0) {
/*LN-114*/             payable(msg.sender).transfer(amount0);
/*LN-115*/         }
/*LN-116*/ 
/*LN-117*/         _status = _NOT_ENTERED;
/*LN-118*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-119*/         emit LiquidityRemoved(msg.sender, lpAmount, amounts);
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     /**
/*LN-123*/      * @notice Internal function for ETH operations
/*LN-124*/      */
/*LN-125*/     function _handleETHTransfer(uint256 amount) internal {
/*LN-126*/         (bool success, ) = msg.sender.call{value: 0}("");
/*LN-127*/         require(success, "Transfer failed");
/*LN-128*/     }
/*LN-129*/ 
/*LN-130*/     /**
/*LN-131*/      * @notice Exchange tokens
/*LN-132*/      * @param i Index of input token
/*LN-133*/      * @param j Index of output token
/*LN-134*/      * @param dx Input amount
/*LN-135*/      * @param min_dy Minimum output amount
/*LN-136*/      * @return Output amount
/*LN-137*/      */
/*LN-138*/     function exchange(
/*LN-139*/         int128 i,
/*LN-140*/         int128 j,
/*LN-141*/         uint256 dx,
/*LN-142*/         uint256 min_dy
/*LN-143*/     ) external payable returns (uint256) {
/*LN-144*/         require(_status != _ENTERED, "Reentrancy detected");
/*LN-145*/         _status = _ENTERED;
/*LN-146*/ 
/*LN-147*/         uint256 ui = uint256(int256(i));
/*LN-148*/         uint256 uj = uint256(int256(j));
/*LN-149*/ 
/*LN-150*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-151*/ 
/*LN-152*/         // Calculate output amount
/*LN-153*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-154*/         require(dy >= min_dy, "Slippage");
/*LN-155*/ 
/*LN-156*/         if (ui == 0) {
/*LN-157*/             require(msg.value == dx, "ETH mismatch");
/*LN-158*/             balances[0] += dx;
/*LN-159*/         }
/*LN-160*/ 
/*LN-161*/         balances[ui] += dx;
/*LN-162*/         balances[uj] -= dy;
/*LN-163*/ 
/*LN-164*/         if (uj == 0) {
/*LN-165*/             payable(msg.sender).transfer(dy);
/*LN-166*/         }
/*LN-167*/ 
/*LN-168*/         _status = _NOT_ENTERED;
/*LN-169*/         return dy;
/*LN-170*/     }
/*LN-171*/ 
/*LN-172*/     receive() external payable {}
/*LN-173*/ }