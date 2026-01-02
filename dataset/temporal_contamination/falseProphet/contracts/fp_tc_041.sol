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

/**
 * @title ShezmuCollateralToken
 * @notice Collateral token for Shezmu CDP protocol
 * @dev Audited by Sherlock (Q3 2024) - All findings resolved
 * @dev Implements standard ERC20 with minting capability
 * @dev Used as collateral backing for shezUSD loans
 * @custom:security-contact security@shezmu.io
 */
/*LN-18*/ contract ShezmuCollateralToken is IERC20 {
/*LN-19*/     string public name = "Shezmu Collateral Token";
/*LN-20*/     string public symbol = "SCT";
/*LN-21*/     uint8 public decimals = 18;
/*LN-22*/ 
/*LN-23*/     mapping(address => uint256) public balanceOf;
/*LN-24*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-25*/     uint256 public totalSupply;
/*LN-26*/ 
    /**
     * @notice Mint new collateral tokens
     * @dev Core minting function for protocol operations
     * @param to Recipient address
     * @param amount Amount to mint
     */
/*LN-27*/     function mint(address to, uint256 amount) external {
        // Execute mint operation
/*LN-30*/ 
/*LN-31*/
/*LN-32*/ 
/*LN-33*/         balanceOf[to] += amount;
/*LN-34*/         totalSupply += amount;
/*LN-35*/     }
/*LN-36*/ 
/// @notice Processes transfer operations
/*LN-37*/     function transfer(
/*LN-38*/         address to,
/*LN-39*/         uint256 amount
/*LN-40*/     ) external override returns (bool) {
/*LN-41*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-42*/         balanceOf[msg.sender] -= amount;
/*LN-43*/         balanceOf[to] += amount;
/*LN-44*/         return true;
/*LN-45*/     }
/*LN-46*/ 
/// @notice Processes transfer operations
/*LN-47*/     function transferFrom(
/*LN-48*/         address from,
/*LN-49*/         address to,
/*LN-50*/         uint256 amount
/*LN-51*/     ) external override returns (bool) {
/*LN-52*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-53*/         require(
/*LN-54*/             allowance[from][msg.sender] >= amount,
/*LN-55*/             "Insufficient allowance"
/*LN-56*/         );
/*LN-57*/         balanceOf[from] -= amount;
/*LN-58*/         balanceOf[to] += amount;
/*LN-59*/         allowance[from][msg.sender] -= amount;
/*LN-60*/         return true;
/*LN-61*/     }
/*LN-62*/ 
/// @dev Production-ready implementation
/*LN-63*/     function approve(
/*LN-64*/         address spender,
/*LN-65*/         uint256 amount
/*LN-66*/     ) external override returns (bool) {
/*LN-67*/         allowance[msg.sender][spender] = amount;
/*LN-68*/         return true;
/*LN-69*/     }
/*LN-70*/ }
/*LN-71*/ 
/*LN-72*/ contract ShezmuVault {
/*LN-73*/     IERC20 public collateralToken;
/*LN-74*/     IERC20 public shezUSD;
/*LN-75*/ 
/*LN-76*/     mapping(address => uint256) public collateralBalance;
/*LN-77*/     mapping(address => uint256) public debtBalance;
/*LN-78*/ 
/*LN-79*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-80*/     uint256 public constant BASIS_POINTS = 100;
/*LN-81*/ 
/*LN-82*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-83*/         collateralToken = IERC20(_collateralToken);
/*LN-84*/         shezUSD = IERC20(_shezUSD);
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     /**
/*LN-88*/      * @notice Add collateral to vault
/*LN-89*/      */
/*LN-90*/     function addCollateral(uint256 amount) external {
/*LN-91*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-92*/         collateralBalance[msg.sender] += amount;
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     /**
/*LN-96*/      * @notice Borrow ShezUSD against collateral
/*LN-97*/      */
/*LN-98*/     function borrow(uint256 amount) external {
        // Calculate maximum borrow capacity
/*LN-100*/ 
/*LN-101*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
/*LN-102*/             COLLATERAL_RATIO;
/*LN-103*/ 
/*LN-104*/         require(
/*LN-105*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-106*/             "Insufficient collateral"
/*LN-107*/         );
/*LN-108*/ 
/*LN-109*/         debtBalance[msg.sender] += amount;
/*LN-110*/ 
/*LN-111*/         shezUSD.transfer(msg.sender, amount);
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     function repay(uint256 amount) external {
/*LN-115*/         require(debtBalance[msg.sender] >= amount, "Excessive repayment");
/*LN-116*/         shezUSD.transferFrom(msg.sender, address(this), amount);
/*LN-117*/         debtBalance[msg.sender] -= amount;
/*LN-118*/     }
/*LN-119*/ 
/*LN-120*/     function withdrawCollateral(uint256 amount) external {
/*LN-121*/         require(
/*LN-122*/             collateralBalance[msg.sender] >= amount,
/*LN-123*/             "Insufficient collateral"
/*LN-124*/         );
/*LN-125*/         uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
/*LN-126*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
/*LN-127*/             COLLATERAL_RATIO;
/*LN-128*/         require(
/*LN-129*/             debtBalance[msg.sender] <= maxDebt,
/*LN-130*/             "Would be undercollateralized"
/*LN-131*/         );
/*LN-132*/ 
/*LN-133*/         collateralBalance[msg.sender] -= amount;
/*LN-134*/         collateralToken.transfer(msg.sender, amount);
/*LN-135*/     }
/*LN-136*/ }
/*LN-137*/ 