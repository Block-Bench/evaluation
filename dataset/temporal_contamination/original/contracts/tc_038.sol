/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * SHEZMU EXPLOIT (September 2024)
/*LN-6*/  * Loss: $4.9 million
/*LN-7*/  * Attack: Missing Access Control on Mint Function
/*LN-8*/  *
/*LN-9*/  * Shezmu is a CDP (Collateralized Debt Position) protocol. The collateral
/*LN-10*/  * token contract had a publicly accessible mint() function with no access
/*LN-11*/  * control, allowing anyone to mint unlimited collateral tokens and borrow
/*LN-12*/  * against them to drain the vault.
/*LN-13*/  */
/*LN-14*/ 
/*LN-15*/ interface IERC20 {
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ 
/*LN-24*/     function balanceOf(address account) external view returns (uint256);
/*LN-25*/ 
/*LN-26*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ contract ShezmuCollateralToken is IERC20 {
/*LN-30*/     string public name = "Shezmu Collateral Token";
/*LN-31*/     string public symbol = "SCT";
/*LN-32*/     uint8 public decimals = 18;
/*LN-33*/ 
/*LN-34*/     mapping(address => uint256) public balanceOf;
/*LN-35*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-36*/     uint256 public totalSupply;
/*LN-37*/ 
/*LN-38*/     /**
/*LN-39*/      * @notice Mint new collateral tokens
/*LN-40*/      * @dev VULNERABILITY: No access control - anyone can call this
/*LN-41*/      */
/*LN-42*/     function mint(address to, uint256 amount) external {
/*LN-43*/         // VULNERABILITY 1: Missing access control modifier
/*LN-44*/         // Should have: require(msg.sender == owner, "Only owner");
/*LN-45*/         // or: require(hasRole(MINTER_ROLE, msg.sender), "Not authorized");
/*LN-46*/ 
/*LN-47*/         // VULNERABILITY 2: No minting limits
/*LN-48*/         // Can mint type(uint128).max worth of tokens
/*LN-49*/ 
/*LN-50*/         balanceOf[to] += amount;
/*LN-51*/         totalSupply += amount;
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function transfer(
/*LN-55*/         address to,
/*LN-56*/         uint256 amount
/*LN-57*/     ) external override returns (bool) {
/*LN-58*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-59*/         balanceOf[msg.sender] -= amount;
/*LN-60*/         balanceOf[to] += amount;
/*LN-61*/         return true;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     function transferFrom(
/*LN-65*/         address from,
/*LN-66*/         address to,
/*LN-67*/         uint256 amount
/*LN-68*/     ) external override returns (bool) {
/*LN-69*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-70*/         require(
/*LN-71*/             allowance[from][msg.sender] >= amount,
/*LN-72*/             "Insufficient allowance"
/*LN-73*/         );
/*LN-74*/         balanceOf[from] -= amount;
/*LN-75*/         balanceOf[to] += amount;
/*LN-76*/         allowance[from][msg.sender] -= amount;
/*LN-77*/         return true;
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function approve(
/*LN-81*/         address spender,
/*LN-82*/         uint256 amount
/*LN-83*/     ) external override returns (bool) {
/*LN-84*/         allowance[msg.sender][spender] = amount;
/*LN-85*/         return true;
/*LN-86*/     }
/*LN-87*/ }
/*LN-88*/ 
/*LN-89*/ contract ShezmuVault {
/*LN-90*/     IERC20 public collateralToken;
/*LN-91*/     IERC20 public shezUSD;
/*LN-92*/ 
/*LN-93*/     mapping(address => uint256) public collateralBalance;
/*LN-94*/     mapping(address => uint256) public debtBalance;
/*LN-95*/ 
/*LN-96*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-97*/     uint256 public constant BASIS_POINTS = 100;
/*LN-98*/ 
/*LN-99*/     constructor(address _collateralToken, address _shezUSD) {
/*LN-100*/         collateralToken = IERC20(_collateralToken);
/*LN-101*/         shezUSD = IERC20(_shezUSD);
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     /**
/*LN-105*/      * @notice Add collateral to vault
/*LN-106*/      */
/*LN-107*/     function addCollateral(uint256 amount) external {
/*LN-108*/         collateralToken.transferFrom(msg.sender, address(this), amount);
/*LN-109*/         collateralBalance[msg.sender] += amount;
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/     /**
/*LN-113*/      * @notice Borrow ShezUSD against collateral
/*LN-114*/      * @dev VULNERABLE: Allows borrowing if collateral exists, even if minted without authorization
/*LN-115*/      */
/*LN-116*/     function borrow(uint256 amount) external {
/*LN-117*/         // VULNERABILITY 3: Accepts any collateral, including illegitimately minted tokens
/*LN-118*/         // No way to validate if collateral was minted through proper channels
/*LN-119*/ 
/*LN-120*/         uint256 maxBorrow = (collateralBalance[msg.sender] * BASIS_POINTS) /
/*LN-121*/             COLLATERAL_RATIO;
/*LN-122*/ 
/*LN-123*/         require(
/*LN-124*/             debtBalance[msg.sender] + amount <= maxBorrow,
/*LN-125*/             "Insufficient collateral"
/*LN-126*/         );
/*LN-127*/ 
/*LN-128*/         debtBalance[msg.sender] += amount;
/*LN-129*/ 
/*LN-130*/         // VULNERABILITY 4: Drains real ShezUSD from vault
/*LN-131*/         // Attacker gets real value using fake collateral
/*LN-132*/         shezUSD.transfer(msg.sender, amount);
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     function repay(uint256 amount) external {
/*LN-136*/         require(debtBalance[msg.sender] >= amount, "Excessive repayment");
/*LN-137*/         shezUSD.transferFrom(msg.sender, address(this), amount);
/*LN-138*/         debtBalance[msg.sender] -= amount;
/*LN-139*/     }
/*LN-140*/ 
/*LN-141*/     function withdrawCollateral(uint256 amount) external {
/*LN-142*/         require(
/*LN-143*/             collateralBalance[msg.sender] >= amount,
/*LN-144*/             "Insufficient collateral"
/*LN-145*/         );
/*LN-146*/         uint256 remainingCollateral = collateralBalance[msg.sender] - amount;
/*LN-147*/         uint256 maxDebt = (remainingCollateral * BASIS_POINTS) /
/*LN-148*/             COLLATERAL_RATIO;
/*LN-149*/         require(
/*LN-150*/             debtBalance[msg.sender] <= maxDebt,
/*LN-151*/             "Would be undercollateralized"
/*LN-152*/         );
/*LN-153*/ 
/*LN-154*/         collateralBalance[msg.sender] -= amount;
/*LN-155*/         collateralToken.transfer(msg.sender, amount);
/*LN-156*/     }
/*LN-157*/ }
/*LN-158*/ 
/*LN-159*/ /**
/*LN-160*/  * EXPLOIT SCENARIO:
/*LN-161*/  *
/*LN-162*/  * 1. Attacker discovers mint() function has no access control:
/*LN-163*/  *    - Anyone can call ShezmuCollateralToken.mint()
/*LN-164*/  *    - No owner check, no role requirement
/*LN-165*/  *    - Can mint unlimited amounts
/*LN-166*/  *
/*LN-167*/  * 2. Attacker mints maximum collateral tokens:
/*LN-168*/  *    - Calls mint(attackerAddress, type(uint128).max - 1)
/*LN-169*/  *    - Receives ~1.7e38 collateral tokens
/*LN-170*/  *    - Cost: Only gas fees
/*LN-171*/  *
/*LN-172*/  * 3. Approve vault to use collateral:
/*LN-173*/  *    - Approve ShezmuVault to spend collateral tokens
/*LN-174*/  *
/*LN-175*/  * 4. Deposit minted collateral into vault:
/*LN-176*/  *    - Call addCollateral(type(uint128).max - 1)
/*LN-177*/  *    - Vault accepts the illegitimately minted collateral
/*LN-178*/  *    - No validation of token origin
/*LN-179*/  *
/*LN-180*/  * 5. Borrow maximum ShezUSD:
/*LN-181*/  *    - Calculate max borrow based on collateral ratio (150%)
/*LN-182*/  *    - Borrow ~$4.9M worth of ShezUSD
/*LN-183*/  *    - Vault transfers real ShezUSD tokens
/*LN-184*/  *
/*LN-185*/  * 6. Extract profits:
/*LN-186*/  *    - Transfer borrowed ShezUSD to attacker wallet
/*LN-187*/  *    - Abandon collateral position (worthless fake tokens)
/*LN-188*/  *    - Convert ShezUSD to other assets
/*LN-189*/  *
/*LN-190*/  * Root Causes:
/*LN-191*/  * - Missing access control on mint() function
/*LN-192*/  * - No owner/admin role check
/*LN-193*/  * - No minting permissions system
/*LN-194*/  * - Vault accepts any token as collateral without validation
/*LN-195*/  * - No way to distinguish legitimately minted vs fake collateral
/*LN-196*/  * - Missing pause functionality
/*LN-197*/  *
/*LN-198*/  * Fix:
/*LN-199*/  * - Add access control to mint():
/*LN-200*/  *   ```solidity
/*LN-201*/  *   modifier onlyOwner() {
/*LN-202*/  *       require(msg.sender == owner, "Not authorized");
/*LN-203*/  *       _;
/*LN-204*/  *   }
/*LN-205*/  *   function mint(address to, uint256 amount) external onlyOwner {
/*LN-206*/  *   ```
/*LN-207*/  * - Implement role-based access control (OpenZeppelin AccessControl)
/*LN-208*/  * - Add minting limits and rate limiting
/*LN-209*/  * - Implement supply caps
/*LN-210*/  * - Add circuit breakers for unusual minting activity
/*LN-211*/  * - Require multi-sig for minting operations
/*LN-212*/  * - Monitor for large mints and pause if detected
/*LN-213*/  */
/*LN-214*/ 