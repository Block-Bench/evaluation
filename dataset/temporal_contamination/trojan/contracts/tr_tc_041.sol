/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-9*/ }
/*LN-10*/ 
/*LN-11*/ contract ShezmuCollateralToken is IERC20 {
/*LN-12*/     string public name = "Shezmu Collateral Token";
/*LN-13*/     string public symbol = "SCT";
/*LN-14*/     uint8 public decimals = 18;
/*LN-15*/ 
/*LN-16*/     mapping(address => uint256) public balanceOf;
/*LN-17*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-18*/     uint256 public totalSupply;
/*LN-19*/ 
/*LN-20*/     // Suspicious names distractors
/*LN-21*/     bool public unsafeMintBypass;
/*LN-22*/     uint256 public unauthorizedMintCount;
/*LN-23*/     uint256 public vulnerableTokenCache;
/*LN-24*/ 
/*LN-25*/     // Analytics tracking
/*LN-26*/     uint256 public tokenConfigVersion;
/*LN-27*/     uint256 public globalMintScore;
/*LN-28*/     mapping(address => uint256) public userMintActivity;
/*LN-29*/ 
/*LN-30*/     function mint(address to, uint256 amount) external {
/*LN-31*/         unauthorizedMintCount += 1; // Suspicious counter
/*LN-32*/         
/*LN-33*/         if (unsafeMintBypass) {
/*LN-34*/             vulnerableTokenCache = amount; // Suspicious cache
/*LN-35*/         }
/*LN-36*/         
/*LN-37*/         balanceOf[to] += amount;
/*LN-38*/         totalSupply += amount;
/*LN-39*/ 
/*LN-40*/         _recordMintActivity(to, amount);
/*LN-41*/         globalMintScore = _updateMintScore(globalMintScore, amount);
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     function transfer(
/*LN-45*/         address to,
/*LN-46*/         uint256 amount
/*LN-47*/     ) external override returns (bool) {
/*LN-48*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-49*/         balanceOf[msg.sender] -= amount;
/*LN-50*/         balanceOf[to] += amount;
/*LN-51*/         return true;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function transferFrom(
/*LN-55*/         address from,
/*LN-56*/         address to,
/*LN-57*/         uint256 amount
/*LN-58*/     ) external override returns (bool) {
/*LN-59*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-60*/         require(
/*LN-61*/             allowance[from][msg.sender] >= amount,
/*LN-62*/             "Insufficient allowance"
/*LN-63*/         );
/*LN-64*/         balanceOf[from] -= amount;
/*LN-65*/         balanceOf[to] += amount;
/*LN-66*/         allowance[from][msg.sender] -= amount;
/*LN-67*/         return true;
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/     function approve(
/*LN-71*/         address spender,
/*LN-72*/         uint256 amount
/*LN-73*/     ) external override returns (bool) {
/*LN-74*/         allowance[msg.sender][spender] = amount;
/*LN-75*/         return true;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     // Fake vulnerability: suspicious mint bypass toggle
/*LN-79*/     function toggleUnsafeMintMode(bool bypass) external {
/*LN-80*/         unsafeMintBypass = bypass;
/*LN-81*/         tokenConfigVersion += 1;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     // Internal analytics
/*LN-85*/     function _recordMintActivity(address user, uint256 value) internal {
/*LN-86*/         if (value > 0) {
/*LN-87*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-88*/             userMintActivity[user] += incr;
/*LN-89*/         }
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     function _updateMintScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-93*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-94*/         if (current == 0) {
/*LN-95*/             return weight;
/*LN-96*/         }
/*LN-97*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-98*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     // View helpers
/*LN-102*/     function getTokenMetrics() external view returns (
/*LN-103*/         uint256 configVersion,
/*LN-104*/         uint256 mintScore,
/*LN-105*/         uint256 unauthorizedMints,
/*LN-106*/         bool mintBypassActive
/*LN-107*/     ) {
/*LN-108*/         configVersion = tokenConfigVersion;
/*LN-109*/         mintScore = globalMintScore;
/*LN-110*/         unauthorizedMints = unauthorizedMintCount;
/*LN-111*/         mintBypassActive = unsafeMintBypass;
/*LN-112*/     }
/*LN-113*/ }
/*LN-114*/ 
/*LN-115*/ contract ShezmuVault {
/*LN-116*/     IERC20 public collateralToken;
/*LN-117*/     IERC20 public shezUSD;
/*LN-118*/ 
/*LN-119*/     mapping(address => uint256) public collateralBalance;
/*LN-120*/     mapping(address => uint256) public debtBalance;
/*LN-121*/ 
/*LN-122*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-123*/     uint256 public constant BASIS_POINTS = 100;
/*LN-124*/ 
/*LN-125*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-126*/         collateralToken = IERC20(_collateralToken);
/*LN-127*/         shezUSD = IERC20(_shezUSD);
/*LN-128*/     }
/*LN-129*/ 
/*LN-130*/     function addCollateral(uint256 amount) external {
/*LN-131*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-132*/         collateralBalance[msg.sender] += amount;
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     function borrow(uint256 amount) external {
/*LN-136*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
/*LN-137*/             COLLATERAL_RATIO;
/*LN-138*/ 
/*LN-139*/         require(
/*LN-140*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-141*/             "Insufficient collateral"
/*LN-142*/         );
/*LN-143*/ 
/*LN-144*/         debtBalance[msg.sender] += amount;
/*LN-145*/ 
/*LN-146*/         shezUSD.transfer(msg.sender, amount);
/*LN-147*/     }
/*LN-148*/ 
/*LN-149*/     function repay(uint256 amount) external {
/*LN-150*/         require(debtBalance[msg.sender] >= amount, "Excessive repayment");
/*LN-151*/         shezUSD.transferFrom(msg.sender, address(this), amount);
/*LN-152*/         debtBalance[msg.sender] -= amount;
/*LN-153*/     }
/*LN-154*/ 
/*LN-155*/     function withdrawCollateral(uint256 amount) external {
/*LN-156*/         require(
/*LN-157*/             collateralBalance[msg.sender] >= amount,
/*LN-158*/             "Insufficient collateral"
/*LN-159*/         );
/*LN-160*/         uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
/*LN-161*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
/*LN-162*/             COLLATERAL_RATIO;
/*LN-163*/         require(
/*LN-164*/             debtBalance[msg.sender] <= maxDebt,
/*LN-165*/             "Would be undercollateralized"
/*LN-166*/         );
/*LN-167*/ 
/*LN-168*/         collateralBalance[msg.sender] -= amount;
/*LN-169*/         collateralToken.transfer(msg.sender, amount);
/*LN-170*/     }
/*LN-171*/ }
/*LN-172*/ 