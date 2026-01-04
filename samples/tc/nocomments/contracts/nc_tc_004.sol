/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract StablePool {
/*LN-4*/ 
/*LN-5*/     mapping(uint256 => uint256) public balances;
/*LN-6*/ 
/*LN-7*/ 
/*LN-8*/     mapping(address => uint256) public lpBalances;
/*LN-9*/     uint256 public totalLPSupply;
/*LN-10*/ 
/*LN-11*/     uint256 private _status;
/*LN-12*/     uint256 private constant _NOT_ENTERED = 1;
/*LN-13*/     uint256 private constant _ENTERED = 2;
/*LN-14*/ 
/*LN-15*/     event LiquidityAdded(
/*LN-16*/         address indexed provider,
/*LN-17*/         uint256[2] amounts,
/*LN-18*/         uint256 lpMinted
/*LN-19*/     );
/*LN-20*/     event LiquidityRemoved(
/*LN-21*/         address indexed provider,
/*LN-22*/         uint256 lpBurned,
/*LN-23*/         uint256[2] amounts
/*LN-24*/     );
/*LN-25*/ 
/*LN-26*/     constructor() {
/*LN-27*/         _status = _NOT_ENTERED;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     function add_liquidity(
/*LN-31*/         uint256[2] memory amounts,
/*LN-32*/         uint256 min_mint_amount
/*LN-33*/     ) external payable returns (uint256) {
/*LN-34*/ 
/*LN-35*/         require(amounts[0] == msg.value, "ETH amount mismatch");
/*LN-36*/ 
/*LN-37*/ 
/*LN-38*/         uint256 lpToMint;
/*LN-39*/         if (totalLPSupply == 0) {
/*LN-40*/             lpToMint = amounts[0] + amounts[1];
/*LN-41*/         } else {
/*LN-42*/ 
/*LN-43*/             uint256 totalValue = balances[0] + balances[1];
/*LN-44*/             lpToMint = ((amounts[0] + amounts[1]) * totalLPSupply) / totalValue;
/*LN-45*/         }
/*LN-46*/ 
/*LN-47*/         require(lpToMint >= min_mint_amount, "Slippage");
/*LN-48*/ 
/*LN-49*/         balances[0] += amounts[0];
/*LN-50*/         balances[1] += amounts[1];
/*LN-51*/ 
/*LN-52*/ 
/*LN-53*/         lpBalances[msg.sender] += lpToMint;
/*LN-54*/         totalLPSupply += lpToMint;
/*LN-55*/ 
/*LN-56*/         if (amounts[0] > 0) {
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/             _handleETHTransfer(amounts[0]);
/*LN-60*/         }
/*LN-61*/ 
/*LN-62*/         emit LiquidityAdded(msg.sender, amounts, lpToMint);
/*LN-63*/         return lpToMint;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/ 
/*LN-67*/     function remove_liquidity(
/*LN-68*/         uint256 lpAmount,
/*LN-69*/         uint256[2] memory min_amounts
/*LN-70*/     ) external {
/*LN-71*/         require(lpBalances[msg.sender] >= lpAmount, "Insufficient LP");
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/         uint256 amount0 = (lpAmount * balances[0]) / totalLPSupply;
/*LN-75*/         uint256 amount1 = (lpAmount * balances[1]) / totalLPSupply;
/*LN-76*/ 
/*LN-77*/         require(
/*LN-78*/             amount0 >= min_amounts[0] && amount1 >= min_amounts[1],
/*LN-79*/             "Slippage"
/*LN-80*/         );
/*LN-81*/ 
/*LN-82*/ 
/*LN-83*/         lpBalances[msg.sender] -= lpAmount;
/*LN-84*/         totalLPSupply -= lpAmount;
/*LN-85*/ 
/*LN-86*/ 
/*LN-87*/         balances[0] -= amount0;
/*LN-88*/         balances[1] -= amount1;
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         if (amount0 > 0) {
/*LN-92*/             payable(msg.sender).transfer(amount0);
/*LN-93*/         }
/*LN-94*/ 
/*LN-95*/         uint256[2] memory amounts = [amount0, amount1];
/*LN-96*/         emit LiquidityRemoved(msg.sender, lpAmount, amounts);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function _handleETHTransfer(uint256 amount) internal {
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/         (bool success, ) = msg.sender.call{value: 0}("");
/*LN-103*/         require(success, "Transfer failed");
/*LN-104*/     }
/*LN-105*/ 
/*LN-106*/ 
/*LN-107*/     function exchange(
/*LN-108*/         int128 i,
/*LN-109*/         int128 j,
/*LN-110*/         uint256 dx,
/*LN-111*/         uint256 min_dy
/*LN-112*/     ) external payable returns (uint256) {
/*LN-113*/         uint256 ui = uint256(int256(i));
/*LN-114*/         uint256 uj = uint256(int256(j));
/*LN-115*/ 
/*LN-116*/         require(ui < 2 && uj < 2 && ui != uj, "Invalid indices");
/*LN-117*/ 
/*LN-118*/ 
/*LN-119*/         uint256 dy = (dx * balances[uj]) / (balances[ui] + dx);
/*LN-120*/         require(dy >= min_dy, "Slippage");
/*LN-121*/ 
/*LN-122*/         if (ui == 0) {
/*LN-123*/             require(msg.value == dx, "ETH mismatch");
/*LN-124*/             balances[0] += dx;
/*LN-125*/         }
/*LN-126*/ 
/*LN-127*/         balances[ui] += dx;
/*LN-128*/         balances[uj] -= dy;
/*LN-129*/ 
/*LN-130*/         if (uj == 0) {
/*LN-131*/             payable(msg.sender).transfer(dy);
/*LN-132*/         }
/*LN-133*/ 
/*LN-134*/         return dy;
/*LN-135*/     }
/*LN-136*/ 
/*LN-137*/     receive() external payable {
/*LN-138*/     }
/*LN-139*/ }