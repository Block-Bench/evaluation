/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Compound cTUSD - Token Sweep Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability in Compound's token sweep
/*LN-7*/  * @dev March 2022 - Allowed sweeping of TUSD due to contract upgrade confusion
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: sweepToken function allowed sweeping upgraded token address
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * TUSD token was upgraded to a new implementation, but the old implementation
/*LN-13*/  * address was still registered as the "underlying" token in cTUSD. The sweepToken
/*LN-14*/  * function was designed to sweep "mistakenly sent" tokens, but it only checked
/*LN-15*/  * against the old TUSD address, allowing the new TUSD address to be swept.
/*LN-16*/  *
/*LN-17*/  * ATTACK VECTOR:
/*LN-18*/  * 1. TUSD upgraded its token contract to new address
/*LN-19*/  * 2. cTUSD contract still referenced old TUSD address as "underlying"
/*LN-20*/  * 3. Attacker noticed this discrepancy
/*LN-21*/  * 4. Called sweepToken(newTUSDAddress)
/*LN-22*/  * 5. Function checked: newTUSDAddress != oldTUSDAddress ✓ (passes)
/*LN-23*/  * 6. Swept all TUSD from cTUSD contract to attacker
/*LN-24*/  *
/*LN-25*/  * This is a logic error where the contract failed to account for token upgrades.
/*LN-26*/  */
/*LN-27*/ 
/*LN-28*/ interface IERC20 {
/*LN-29*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-30*/ 
/*LN-31*/     function balanceOf(address account) external view returns (uint256);
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ contract VulnerableCompoundCToken {
/*LN-35*/     address public underlying; // Old TUSD address
/*LN-36*/     address public admin;
/*LN-37*/ 
/*LN-38*/     mapping(address => uint256) public accountTokens;
/*LN-39*/     uint256 public totalSupply;
/*LN-40*/ 
/*LN-41*/     // The actual TUSD token was upgraded, but this still points to old address
/*LN-42*/     address public constant OLD_TUSD =
/*LN-43*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-44*/     address public constant NEW_TUSD =
/*LN-45*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-46*/ 
/*LN-47*/     constructor() {
/*LN-48*/         admin = msg.sender;
/*LN-49*/         underlying = OLD_TUSD; // Contract references old TUSD address
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     /**
/*LN-53*/      * @notice Supply tokens to the market
/*LN-54*/      */
/*LN-55*/     function mint(uint256 amount) external {
/*LN-56*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-57*/         accountTokens[msg.sender] += amount;
/*LN-58*/         totalSupply += amount;
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     /**
/*LN-62*/      * @notice Sweep accidentally sent tokens
/*LN-63*/      * @param token Address of token to sweep
/*LN-64*/      *
/*LN-65*/      * VULNERABILITY IS HERE:
/*LN-66*/      * The function only checks if token != underlying (old TUSD address).
/*LN-67*/      * It doesn't account for the fact that TUSD was upgraded to a new address.
/*LN-68*/      * So sweepToken(NEW_TUSD) passes the check because NEW_TUSD != OLD_TUSD.
/*LN-69*/      *
/*LN-70*/      * Vulnerable logic:
/*LN-71*/      * 1. Check token != underlying (line 76)
/*LN-72*/      * 2. underlying = OLD_TUSD address
/*LN-73*/      * 3. Attacker calls sweepToken(NEW_TUSD)
/*LN-74*/      * 4. NEW_TUSD != OLD_TUSD, so check passes
/*LN-75*/      * 5. Transfers all NEW_TUSD tokens to caller
/*LN-76*/      * 6. But NEW_TUSD is the actual underlying asset!
/*LN-77*/      */
/*LN-78*/     function sweepToken(address token) external {
/*LN-79*/         // VULNERABLE: Only checks against OLD_TUSD address
/*LN-80*/         // Doesn't account for token upgrades where underlying moved to new address
/*LN-81*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-82*/ 
/*LN-83*/         // This allows sweeping NEW_TUSD because NEW_TUSD != OLD_TUSD
/*LN-84*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-85*/         IERC20(token).transfer(msg.sender, balance);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     /**
/*LN-89*/      * @notice Redeem cTokens for underlying
/*LN-90*/      */
/*LN-91*/     function redeem(uint256 amount) external {
/*LN-92*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-93*/ 
/*LN-94*/         accountTokens[msg.sender] -= amount;
/*LN-95*/         totalSupply -= amount;
/*LN-96*/ 
/*LN-97*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-98*/     }
/*LN-99*/ }
/*LN-100*/ 
/*LN-101*/ /**
/*LN-102*/  * Example attack:
/*LN-103*/  *
/*LN-104*/  * 1. Observe that TUSD token upgraded from OLD_TUSD to NEW_TUSD
/*LN-105*/  * 2. Notice cTUSD contract still references OLD_TUSD as underlying
/*LN-106*/  * 3. Call cTUSD.sweepToken(NEW_TUSD)
/*LN-107*/  * 4. Function checks: NEW_TUSD != OLD_TUSD ✓ (passes)
/*LN-108*/  * 5. All TUSD swept from cTUSD to attacker
/*LN-109*/  * 6. Legitimate users can't redeem their cTUSD anymore
/*LN-110*/  *
/*LN-111*/  * REAL-WORLD IMPACT:
/*LN-112*/  * - Affected Compound cTUSD market
/*LN-113*/  * - Allowed sweeping of actual underlying asset
/*LN-114*/  * - No funds lost because exploiter returned them
/*LN-115*/  * - Highlighted risks of token upgrades in DeFi
/*LN-116*/  *
/*LN-117*/  * FIX:
/*LN-118*/  * Track all valid underlying token addresses, including upgraded versions:
/*LN-119*/  *
/*LN-120*/  * mapping(address => bool) public isUnderlying;
/*LN-121*/  *
/*LN-122*/  * constructor() {
/*LN-123*/  *     admin = msg.sender;
/*LN-124*/  *     isUnderlying[OLD_TUSD] = true;
/*LN-125*/  *     isUnderlying[NEW_TUSD] = true;  // Add new address
/*LN-126*/  * }
/*LN-127*/  *
/*LN-128*/  * function sweepToken(address token) external {
/*LN-129*/  *     require(!isUnderlying[token], "Cannot sweep underlying token");
/*LN-130*/  *     uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-131*/  *     IERC20(token).transfer(msg.sender, balance);
/*LN-132*/  * }
/*LN-133*/  *
/*LN-134*/  * Or check both old and new addresses:
/*LN-135*/  *
/*LN-136*/  * function sweepToken(address token) external {
/*LN-137*/  *     require(
/*LN-138*/  *         token != OLD_TUSD && token != NEW_TUSD,
/*LN-139*/  *         "Cannot sweep underlying"
/*LN-140*/  *     );
/*LN-141*/  *     uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-142*/  *     IERC20(token).transfer(msg.sender, balance);
/*LN-143*/  * }
/*LN-144*/  *
/*LN-145*/  *
/*LN-146*/  * KEY LESSON:
/*LN-147*/  * When tokens upgrade to new addresses, all dependent contracts must be updated.
/*LN-148*/  * sweepToken and similar "rescue" functions must account for all valid underlying
/*LN-149*/  * token addresses, including legacy and upgraded versions.
/*LN-150*/  * Token upgrades create subtle vulnerabilities in integration contracts.
/*LN-151*/  */
/*LN-152*/ 