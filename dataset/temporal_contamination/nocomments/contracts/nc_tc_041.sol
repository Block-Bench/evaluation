/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract CollateralToken is IERC20 {
/*LN-18*/     string public name = "Shezmu Collateral Token";
/*LN-19*/     string public symbol = "SCT";
/*LN-20*/     uint8 public decimals = 18;
/*LN-21*/ 
/*LN-22*/     mapping(address => uint256) public balanceOf;
/*LN-23*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-24*/     uint256 public totalSupply;
/*LN-25*/ 
/*LN-26*/     function mint(address to, uint256 amount) external {
/*LN-27*/ 
/*LN-28*/ 
/*LN-29*/         balanceOf[to] += amount;
/*LN-30*/         totalSupply += amount;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function transfer(
/*LN-34*/         address to,
/*LN-35*/         uint256 amount
/*LN-36*/     ) external override returns (bool) {
/*LN-37*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-38*/         balanceOf[msg.sender] -= amount;
/*LN-39*/         balanceOf[to] += amount;
/*LN-40*/         return true;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function transferFrom(
/*LN-44*/         address from,
/*LN-45*/         address to,
/*LN-46*/         uint256 amount
/*LN-47*/     ) external override returns (bool) {
/*LN-48*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-49*/         require(
/*LN-50*/             allowance[from][msg.sender] >= amount,
/*LN-51*/             "Insufficient allowance"
/*LN-52*/         );
/*LN-53*/         balanceOf[from] -= amount;
/*LN-54*/         balanceOf[to] += amount;
/*LN-55*/         allowance[from][msg.sender] -= amount;
/*LN-56*/         return true;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     function approve(
/*LN-60*/         address spender,
/*LN-61*/         uint256 amount
/*LN-62*/     ) external override returns (bool) {
/*LN-63*/         allowance[msg.sender][spender] = amount;
/*LN-64*/         return true;
/*LN-65*/     }
/*LN-66*/ }
/*LN-67*/ 
/*LN-68*/ contract CollateralVault {
/*LN-69*/     IERC20 public collateralToken;
/*LN-70*/     IERC20 public shezUSD;
/*LN-71*/ 
/*LN-72*/     mapping(address => uint256) public collateralBalance;
/*LN-73*/     mapping(address => uint256) public debtBalance;
/*LN-74*/ 
/*LN-75*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-76*/     uint256 public constant BASIS_POINTS = 100;
/*LN-77*/ 
/*LN-78*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-79*/         collateralToken = IERC20(_collateralToken);
/*LN-80*/         shezUSD = IERC20(_shezUSD);
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/ 
/*LN-84*/     function addCollateral(uint256 amount) external {
/*LN-85*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-86*/         collateralBalance[msg.sender] += amount;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/     function borrow(uint256 amount) external {
/*LN-91*/ 
/*LN-92*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
/*LN-93*/             COLLATERAL_RATIO;
/*LN-94*/ 
/*LN-95*/         require(
/*LN-96*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-97*/             "Insufficient collateral"
/*LN-98*/         );
/*LN-99*/ 
/*LN-100*/         debtBalance[msg.sender] += amount;
/*LN-101*/ 
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
/*LN-117*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
/*LN-118*/             COLLATERAL_RATIO;
/*LN-119*/         require(
/*LN-120*/             debtBalance[msg.sender] <= maxDebt,
/*LN-121*/             "Would be undercollateralized"
/*LN-122*/         );
/*LN-123*/ 
/*LN-124*/         collateralBalance[msg.sender] -= amount;
/*LN-125*/         collateralToken.transfer(msg.sender, amount);
/*LN-126*/     }
/*LN-127*/ }