/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ 
/*LN-15*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ contract CollateralToken is IERC20 {
/*LN-19*/     string public name = "Shezmu Collateral Token";
/*LN-20*/     string public symbol = "SCT";
/*LN-21*/     uint8 public decimals = 18;
/*LN-22*/ 
/*LN-23*/     mapping(address => uint256) public balanceOf;
/*LN-24*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-25*/     uint256 public totalSupply;
/*LN-26*/ 
/*LN-27*/     function mint(address to, uint256 amount) external {
/*LN-28*/ 
/*LN-29*/         // Can mint type(uint128).max worth of tokens
/*LN-30*/ 
/*LN-31*/         balanceOf[to] += amount;
/*LN-32*/         totalSupply += amount;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/     function transfer(
/*LN-36*/         address to,
/*LN-37*/         uint256 amount
/*LN-38*/     ) external override returns (bool) {
/*LN-39*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-40*/         balanceOf[msg.sender] -= amount;
/*LN-41*/         balanceOf[to] += amount;
/*LN-42*/         return true;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     function transferFrom(
/*LN-46*/         address from,
/*LN-47*/         address to,
/*LN-48*/         uint256 amount
/*LN-49*/     ) external override returns (bool) {
/*LN-50*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-51*/         require(
/*LN-52*/             allowance[from][msg.sender] >= amount,
/*LN-53*/             "Insufficient allowance"
/*LN-54*/         );
/*LN-55*/         balanceOf[from] -= amount;
/*LN-56*/         balanceOf[to] += amount;
/*LN-57*/         allowance[from][msg.sender] -= amount;
/*LN-58*/         return true;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function approve(
/*LN-62*/         address spender,
/*LN-63*/         uint256 amount
/*LN-64*/     ) external override returns (bool) {
/*LN-65*/         allowance[msg.sender][spender] = amount;
/*LN-66*/         return true;
/*LN-67*/     }
/*LN-68*/ }
/*LN-69*/ 
/*LN-70*/ contract CollateralVault {
/*LN-71*/     IERC20 public collateralToken;
/*LN-72*/     IERC20 public shezUSD;
/*LN-73*/ 
/*LN-74*/     mapping(address => uint256) public collateralBalance;
/*LN-75*/     mapping(address => uint256) public debtBalance;
/*LN-76*/ 
/*LN-77*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-78*/     uint256 public constant BASIS_POINTS = 100;
/*LN-79*/ 
/*LN-80*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-81*/         collateralToken = IERC20(_collateralToken);
/*LN-82*/         shezUSD = IERC20(_shezUSD);
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     /**
/*LN-86*/      * @notice Add collateral to vault
/*LN-87*/      */
/*LN-88*/     function addCollateral(uint256 amount) external {
/*LN-89*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-90*/         collateralBalance[msg.sender] += amount;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Borrow ShezUSD against collateral
/*LN-95*/      */
/*LN-96*/     function borrow(uint256 amount) external {
/*LN-97*/ 
/*LN-98*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
/*LN-99*/             COLLATERAL_RATIO;
/*LN-100*/ 
/*LN-101*/         require(
/*LN-102*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-103*/             "Insufficient collateral"
/*LN-104*/         );
/*LN-105*/ 
/*LN-106*/         debtBalance[msg.sender] += amount;
/*LN-107*/ 
/*LN-108*/         shezUSD.transfer(msg.sender, amount);
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function repay(uint256 amount) external {
/*LN-112*/         require(debtBalance[msg.sender] >= amount, "Excessive repayment");
/*LN-113*/         shezUSD.transferFrom(msg.sender, address(this), amount);
/*LN-114*/         debtBalance[msg.sender] -= amount;
/*LN-115*/     }
/*LN-116*/ 
/*LN-117*/     function withdrawCollateral(uint256 amount) external {
/*LN-118*/         require(
/*LN-119*/             collateralBalance[msg.sender] >= amount,
/*LN-120*/             "Insufficient collateral"
/*LN-121*/         );
/*LN-122*/         uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
/*LN-123*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
/*LN-124*/             COLLATERAL_RATIO;
/*LN-125*/         require(
/*LN-126*/             debtBalance[msg.sender] <= maxDebt,
/*LN-127*/             "Would be undercollateralized"
/*LN-128*/         );
/*LN-129*/ 
/*LN-130*/         collateralBalance[msg.sender] -= amount;
/*LN-131*/         collateralToken.transfer(msg.sender, amount);
/*LN-132*/     }
/*LN-133*/ }
/*LN-134*/ 