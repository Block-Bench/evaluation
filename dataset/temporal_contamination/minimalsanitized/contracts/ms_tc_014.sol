/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface ICurve3Pool {
/*LN-5*/     function add_liquidity(
/*LN-6*/         uint256[3] memory amounts,
/*LN-7*/         uint256 min_mint_amount
/*LN-8*/     ) external;
/*LN-9*/ 
/*LN-10*/     function remove_liquidity_imbalance(
/*LN-11*/         uint256[3] memory amounts,
/*LN-12*/         uint256 max_burn_amount
/*LN-13*/     ) external;
/*LN-14*/ 
/*LN-15*/     function get_virtual_price() external view returns (uint256);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface IERC20 {
/*LN-19*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-20*/ 
/*LN-21*/     function transferFrom(
/*LN-22*/         address from,
/*LN-23*/         address to,
/*LN-24*/         uint256 amount
/*LN-25*/     ) external returns (bool);
/*LN-26*/ 
/*LN-27*/     function balanceOf(address account) external view returns (uint256);
/*LN-28*/ 
/*LN-29*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-30*/ }
/*LN-31*/ 
/*LN-32*/ contract YearnVault {
/*LN-33*/     IERC20 public dai;
/*LN-34*/     IERC20 public crv3; // Curve 3pool LP token
/*LN-35*/     ICurve3Pool public curve3Pool;
/*LN-36*/ 
/*LN-37*/     mapping(address => uint256) public shares;
/*LN-38*/     uint256 public totalShares;
/*LN-39*/     uint256 public totalDeposits;
/*LN-40*/ 
/*LN-41*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-42*/ 
/*LN-43*/     constructor(address _dai, address _crv3, address _curve3Pool) {
/*LN-44*/         dai = IERC20(_dai);
/*LN-45*/         crv3 = IERC20(_crv3);
/*LN-46*/         curve3Pool = ICurve3Pool(_curve3Pool);
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      * @notice Deposit DAI into the vault
/*LN-51*/      */
/*LN-52*/     function deposit(uint256 amount) external {
/*LN-53*/         dai.transferFrom(msg.sender, address(this), amount);
/*LN-54*/ 
/*LN-55*/         uint256 shareAmount;
/*LN-56*/         if (totalShares == 0) {
/*LN-57*/             shareAmount = amount;
/*LN-58*/         } else {
/*LN-59*/             // Calculate shares based on current vault value
/*LN-60*/             shareAmount = (amount * totalShares) / totalDeposits;
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         shares[msg.sender] += shareAmount;
/*LN-64*/         totalShares += shareAmount;
/*LN-65*/         totalDeposits += amount;
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/     function earn() external {
/*LN-69*/         uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-70*/         require(
/*LN-71*/             vaultBalance >= MIN_EARN_THRESHOLD,
/*LN-72*/             "Insufficient balance to earn"
/*LN-73*/         );
/*LN-74*/ 
/*LN-75*/         uint256 virtualPrice = curve3Pool.get_virtual_price();
/*LN-76*/ 
/*LN-77*/         // Add all DAI to Curve pool
/*LN-78*/         dai.approve(address(curve3Pool), vaultBalance);
/*LN-79*/         uint256[3] memory amounts = [vaultBalance, 0, 0]; // Only DAI
/*LN-80*/         curve3Pool.add_liquidity(amounts, 0);
/*LN-81*/ 
/*LN-82*/         
/*LN-83*/         
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     /**
/*LN-87*/      * @notice Withdraw shares from vault
/*LN-88*/      */
/*LN-89*/     function withdrawAll() external {
/*LN-90*/         uint256 userShares = shares[msg.sender];
/*LN-91*/         require(userShares > 0, "No shares");
/*LN-92*/ 
/*LN-93*/         // Calculate withdrawal amount based on current total value
/*LN-94*/         uint256 withdrawAmount = (userShares * totalDeposits) / totalShares;
/*LN-95*/ 
/*LN-96*/         shares[msg.sender] = 0;
/*LN-97*/         totalShares -= userShares;
/*LN-98*/         totalDeposits -= withdrawAmount;
/*LN-99*/ 
/*LN-100*/         dai.transfer(msg.sender, withdrawAmount);
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     /**
/*LN-104*/      * @notice Get vault's total value including Curve position
/*LN-105*/      */
/*LN-106*/     function balance() public view returns (uint256) {
/*LN-107*/         return
/*LN-108*/             dai.balanceOf(address(this)) +
/*LN-109*/             (crv3.balanceOf(address(this)) * curve3Pool.get_virtual_price()) /
/*LN-110*/             1e18;
/*LN-111*/     }
/*LN-112*/ }
/*LN-113*/ 