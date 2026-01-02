/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract ShezmuCollateralToken is IERC20 {
/*LN-16*/     string public name = "Shezmu Collateral Token";
/*LN-17*/     string public symbol = "SCT";
/*LN-18*/     uint8 public decimals = 18;
/*LN-19*/ 
/*LN-20*/     mapping(address => uint256) public balanceOf;
/*LN-21*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-22*/     uint256 public totalSupply;
/*LN-23*/ 
/*LN-24*/     address public owner;
/*LN-25*/ 
/*LN-26*/     constructor() {
/*LN-27*/         owner = msg.sender;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     modifier onlyOwner() {
/*LN-31*/         require(msg.sender == owner, "Not owner");
/*LN-32*/         _;
/*LN-33*/     }
/*LN-34*/ 
/*LN-35*/     function mint(address to, uint256 amount) external onlyOwner {
/*LN-36*/         balanceOf[to] += amount;
/*LN-37*/         totalSupply += amount;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     function transfer(
/*LN-41*/         address to,
/*LN-42*/         uint256 amount
/*LN-43*/     ) external override returns (bool) {
/*LN-44*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-45*/         balanceOf[msg.sender] -= amount;
/*LN-46*/         balanceOf[to] += amount;
/*LN-47*/         return true;
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function transferFrom(
/*LN-51*/         address from,
/*LN-52*/         address to,
/*LN-53*/         uint256 amount
/*LN-54*/     ) external override returns (bool) {
/*LN-55*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-56*/         require(
/*LN-57*/             allowance[from][msg.sender] >= amount,
/*LN-58*/             "Insufficient allowance"
/*LN-59*/         );
/*LN-60*/         balanceOf[from] -= amount;
/*LN-61*/         balanceOf[to] += amount;
/*LN-62*/         allowance[from][msg.sender] -= amount;
/*LN-63*/         return true;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function approve(
/*LN-67*/         address spender,
/*LN-68*/         uint256 amount
/*LN-69*/     ) external override returns (bool) {
/*LN-70*/         allowance[msg.sender][spender] = amount;
/*LN-71*/         return true;
/*LN-72*/     }
/*LN-73*/ }
/*LN-74*/ 
/*LN-75*/ contract ShezmuVault {
/*LN-76*/     IERC20 public collateralToken;
/*LN-77*/     IERC20 public shezUSD;
/*LN-78*/ 
/*LN-79*/     mapping(address => uint256) public collateralBalance;
/*LN-80*/     mapping(address => uint256) public debtBalance;
/*LN-81*/ 
/*LN-82*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-83*/     uint256 public constant BASIS_POINTS = 100;
/*LN-84*/ 
/*LN-85*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-86*/         collateralToken = IERC20(_collateralToken);
/*LN-87*/         shezUSD = IERC20(_shezUSD);
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function addCollateral(uint256 amount) external {
/*LN-91*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-92*/         collateralBalance[msg.sender] += amount;
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     function borrow(uint256 amount) external {
/*LN-96*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) / COLLATERAL_RATIO;
/*LN-97*/         require(
/*LN-98*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-99*/             "Insufficient collateral"
/*LN-100*/         );
/*LN-101*/         debtBalance[msg.sender] += amount;
/*LN-102*/         shezUSD.transfer(msg.sender, amount);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     function repay(uint256 amount) external {
/*LN-106*/         require(debtBalance[msg.sender] >= amount, "Excessive repayment");
/*LN-107*/         shezUSD.transferFrom(msg.sender, address(this), amount);
/*LN-108*/         debtBalance[msg.sender] -= amount;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function withdrawCollateral(uint256 amount) external {
/*LN-112*/         require(
/*LN-113*/             collateralBalance[msg.sender] >= amount,
/*LN-114*/             "Insufficient collateral"
/*LN-115*/         );
/*LN-116*/         uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
/*LN-117*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) / COLLATERAL_RATIO;
/*LN-118*/         require(
/*LN-119*/             debtBalance[msg.sender] <= maxDebt,
/*LN-120*/             "Would be undercollateralized"
/*LN-121*/         );
/*LN-122*/         collateralBalance[msg.sender] -= amount;
/*LN-123*/         collateralToken.transfer(msg.sender, amount);
/*LN-124*/     }
/*LN-125*/ }
/*LN-126*/ 