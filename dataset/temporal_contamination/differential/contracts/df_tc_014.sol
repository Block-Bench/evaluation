/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Vault Strategy Contract
/*LN-6*/  * @notice Manages deposits and automated yield strategies
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface ICurve3Pool {
/*LN-10*/     function add_liquidity(
/*LN-11*/         uint256[3] memory amounts,
/*LN-12*/         uint256 min_mint_amount
/*LN-13*/     ) external;
/*LN-14*/ 
/*LN-15*/     function remove_liquidity_imbalance(
/*LN-16*/         uint256[3] memory amounts,
/*LN-17*/         uint256 max_burn_amount
/*LN-18*/     ) external;
/*LN-19*/ 
/*LN-20*/     function get_virtual_price() external view returns (uint256);
/*LN-21*/ }
/*LN-22*/ 
/*LN-23*/ interface IERC20 {
/*LN-24*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-25*/ 
/*LN-26*/     function transferFrom(
/*LN-27*/         address from,
/*LN-28*/         address to,
/*LN-29*/         uint256 amount
/*LN-30*/     ) external returns (bool);
/*LN-31*/ 
/*LN-32*/     function balanceOf(address account) external view returns (uint256);
/*LN-33*/ 
/*LN-34*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract YieldVault {
/*LN-38*/     IERC20 public dai;
/*LN-39*/     IERC20 public crv3;
/*LN-40*/     ICurve3Pool public curve3Pool;
/*LN-41*/ 
/*LN-42*/     mapping(address => uint256) public shares;
/*LN-43*/     uint256 public totalShares;
/*LN-44*/     uint256 public totalDeposits;
/*LN-45*/ 
/*LN-46*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-47*/ 
/*LN-48*/     uint256 public twapPrice;
/*LN-49*/     uint256 public lastUpdateTime;
/*LN-50*/ 
/*LN-51*/     constructor(address _dai, address _crv3, address _curve3Pool) {
/*LN-52*/         dai = IERC20(_dai);
/*LN-53*/         crv3 = IERC20(_crv3);
/*LN-54*/         curve3Pool = ICurve3Pool(_curve3Pool);
/*LN-55*/         lastUpdateTime = block.timestamp;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function deposit(uint256 amount) external {
/*LN-59*/         dai.transferFrom(msg.sender, address(this), amount);
/*LN-60*/ 
/*LN-61*/         uint256 shareAmount;
/*LN-62*/         if (totalShares == 0) {
/*LN-63*/             shareAmount = amount;
/*LN-64*/         } else {
/*LN-65*/             shareAmount = (amount * totalShares) / totalDeposits;
/*LN-66*/         }
/*LN-67*/ 
/*LN-68*/         shares[msg.sender] += shareAmount;
/*LN-69*/         totalShares += shareAmount;
/*LN-70*/         totalDeposits += amount;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function earn() external {
/*LN-74*/         uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-75*/         require(
/*LN-76*/             vaultBalance >= MIN_EARN_THRESHOLD,
/*LN-77*/             "Insufficient balance to earn"
/*LN-78*/         );
/*LN-79*/ 
/*LN-80*/         uint256 spotPrice = curve3Pool.get_virtual_price();
/*LN-81*/         uint256 timeElapsed = block.timestamp - lastUpdateTime;
/*LN-82*/         if (timeElapsed > 0) {
/*LN-83*/             twapPrice = (twapPrice * lastUpdateTime + spotPrice * timeElapsed) / block.timestamp;
/*LN-84*/             lastUpdateTime = block.timestamp;
/*LN-85*/         }
/*LN-86*/ 
/*LN-87*/         dai.approve(address(curve3Pool), vaultBalance);
/*LN-88*/         uint256[3] memory amounts = [vaultBalance, 0, 0];
/*LN-89*/         curve3Pool.add_liquidity(amounts, 0);
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     function withdrawAll() external {
/*LN-93*/         uint256 userShares = shares[msg.sender];
/*LN-94*/         require(userShares > 0, "No shares");
/*LN-95*/ 
/*LN-96*/         uint256 withdrawAmount = (userShares * totalDeposits) / totalShares;
/*LN-97*/ 
/*LN-98*/         shares[msg.sender] = 0;
/*LN-99*/         totalShares -= userShares;
/*LN-100*/         totalDeposits -= withdrawAmount;
/*LN-101*/ 
/*LN-102*/         dai.transfer(msg.sender, withdrawAmount);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     function balance() public view returns (uint256) {
/*LN-106*/         return
/*LN-107*/             dai.balanceOf(address(this)) +
/*LN-108*/             (crv3.balanceOf(address(this)) * twapPrice) / 1e18;
/*LN-109*/     }
/*LN-110*/ }
/*LN-111*/ 