/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IStable3Pool {
/*LN-4*/     function add_liquidity(
/*LN-5*/         uint256[3] memory amounts,
/*LN-6*/         uint256 min_mint_amount
/*LN-7*/     ) external;
/*LN-8*/ 
/*LN-9*/     function remove_liquidity_imbalance(
/*LN-10*/         uint256[3] memory amounts,
/*LN-11*/         uint256 max_burn_amount
/*LN-12*/     ) external;
/*LN-13*/ 
/*LN-14*/     function get_virtual_price() external view returns (uint256);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IERC20 {
/*LN-18*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-19*/ 
/*LN-20*/     function transferFrom(
/*LN-21*/         address from,
/*LN-22*/         address to,
/*LN-23*/         uint256 amount
/*LN-24*/     ) external returns (bool);
/*LN-25*/ 
/*LN-26*/     function balanceOf(address account) external view returns (uint256);
/*LN-27*/ 
/*LN-28*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-29*/ }
/*LN-30*/ 
/*LN-31*/ contract YieldVault {
/*LN-32*/     IERC20 public dai;
/*LN-33*/     IERC20 public crv3;
/*LN-34*/     IStable3Pool public stable3Pool;
/*LN-35*/ 
/*LN-36*/     mapping(address => uint256) public shares;
/*LN-37*/     uint256 public totalShares;
/*LN-38*/     uint256 public totalDeposits;
/*LN-39*/ 
/*LN-40*/     uint256 public constant MIN_EARN_THRESHOLD = 1000 ether;
/*LN-41*/ 
/*LN-42*/     constructor(address _dai, address _crv3, address _stable3Pool) {
/*LN-43*/         dai = IERC20(_dai);
/*LN-44*/         crv3 = IERC20(_crv3);
/*LN-45*/         stable3Pool = IStable3Pool(_stable3Pool);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/ 
/*LN-49*/     function deposit(uint256 amount) external {
/*LN-50*/         dai.transferFrom(msg.sender, address(this), amount);
/*LN-51*/ 
/*LN-52*/         uint256 shareAmount;
/*LN-53*/         if (totalShares == 0) {
/*LN-54*/             shareAmount = amount;
/*LN-55*/         } else {
/*LN-56*/ 
/*LN-57*/             shareAmount = (amount * totalShares) / totalDeposits;
/*LN-58*/         }
/*LN-59*/ 
/*LN-60*/         shares[msg.sender] += shareAmount;
/*LN-61*/         totalShares += shareAmount;
/*LN-62*/         totalDeposits += amount;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function earn() external {
/*LN-66*/         uint256 vaultBalance = dai.balanceOf(address(this));
/*LN-67*/         require(
/*LN-68*/             vaultBalance >= MIN_EARN_THRESHOLD,
/*LN-69*/             "Insufficient balance to earn"
/*LN-70*/         );
/*LN-71*/ 
/*LN-72*/         uint256 virtualPrice = stable3Pool.get_virtual_price();
/*LN-73*/ 
/*LN-74*/         dai.approve(address(stable3Pool), vaultBalance);
/*LN-75*/         uint256[3] memory amounts = [vaultBalance, 0, 0];
/*LN-76*/         stable3Pool.add_liquidity(amounts, 0);
/*LN-77*/ 
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/ 
/*LN-81*/     function withdrawAll() external {
/*LN-82*/         uint256 userShares = shares[msg.sender];
/*LN-83*/         require(userShares > 0, "No shares");
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/         uint256 withdrawAmount = (userShares * totalDeposits) / totalShares;
/*LN-87*/ 
/*LN-88*/         shares[msg.sender] = 0;
/*LN-89*/         totalShares -= userShares;
/*LN-90*/         totalDeposits -= withdrawAmount;
/*LN-91*/ 
/*LN-92*/         dai.transfer(msg.sender, withdrawAmount);
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/ 
/*LN-96*/     function balance() public view returns (uint256) {
/*LN-97*/         return
/*LN-98*/             dai.balanceOf(address(this)) +
/*LN-99*/             (crv3.balanceOf(address(this)) * stable3Pool.get_virtual_price()) /
/*LN-100*/             1e18;
/*LN-101*/     }
/*LN-102*/ }