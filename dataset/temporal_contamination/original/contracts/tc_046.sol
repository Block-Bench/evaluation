/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * FIXEDFLOAT EXPLOIT (February 2024)
/*LN-6*/  * Loss: $26 million
/*LN-7*/  * Attack: Private Key Compromise + Unauthorized Withdrawals
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY OVERVIEW:
/*LN-10*/  * FixedFloat, a crypto exchange platform, suffered a massive exploit when attackers
/*LN-11*/  * compromised private keys controlling the platform's hot wallets. The compromised keys
/*LN-12*/  * allowed direct withdrawal of funds without any authorization checks or multi-sig protection.
/*LN-13*/  *
/*LN-14*/  * ROOT CAUSE:
/*LN-15*/  * 1. Single private key controlled withdrawal functions
/*LN-16*/  * 2. No multi-signature requirement for large withdrawals
/*LN-17*/  * 3. Missing timelock for critical operations
/*LN-18*/  * 4. Insufficient monitoring and alerting
/*LN-19*/  * 5. No withdrawal limits or rate limiting
/*LN-20*/  *
/*LN-21*/  * ATTACK FLOW:
/*LN-22*/  * 1. Attackers compromised admin private keys (phishing/malware suspected)
/*LN-23*/  * 2. Used compromised keys to call withdraw() directly
/*LN-24*/  * 3. Drained Bitcoin and Ethereum from hot wallets
/*LN-25*/  * 4. No timelock delayed the malicious withdrawals
/*LN-26*/  * 5. Transferred stolen funds through mixers
/*LN-27*/  * 6. Total loss: ~$26M in BTC and ETH
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ interface IERC20 {
/*LN-31*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-32*/ 
/*LN-33*/     function balanceOf(address account) external view returns (uint256);
/*LN-34*/ }
/*LN-35*/ 
/*LN-36*/ /**
/*LN-37*/  * Simplified model of FixedFloat's vulnerable withdrawal system
/*LN-38*/  */
/*LN-39*/ contract FixedFloatHotWallet {
/*LN-40*/     address public owner;
/*LN-41*/ 
/*LN-42*/     // VULNERABILITY 1: Single owner controls all funds
/*LN-43*/     // No multi-sig, no timelock, no withdrawal limits
/*LN-44*/ 
/*LN-45*/     mapping(address => bool) public authorizedOperators;
/*LN-46*/ 
/*LN-47*/     event Withdrawal(address token, address to, uint256 amount);
/*LN-48*/ 
/*LN-49*/     constructor() {
/*LN-50*/         owner = msg.sender;
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     /**
/*LN-54*/      * @dev VULNERABILITY 2: Single private key compromise = total loss
/*LN-55*/      * @dev VULNERABILITY 3: No multi-signature requirement
/*LN-56*/      */
/*LN-57*/     modifier onlyOwner() {
/*LN-58*/         require(msg.sender == owner, "Not owner");
/*LN-59*/         _;
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     /**
/*LN-63*/      * @dev VULNERABILITY 4: No timelock delay for withdrawals
/*LN-64*/      * @dev VULNERABILITY 5: No maximum withdrawal limits
/*LN-65*/      * @dev VULNERABILITY 6: Can drain entire balance in single transaction
/*LN-66*/      */
/*LN-67*/     function withdraw(
/*LN-68*/         address token,
/*LN-69*/         address to,
/*LN-70*/         uint256 amount
/*LN-71*/     ) external onlyOwner {
/*LN-72*/         // VULNERABILITY 7: No additional authorization checks
/*LN-73*/         // VULNERABILITY 8: No rate limiting
/*LN-74*/         // VULNERABILITY 9: No monitoring or pause mechanism
/*LN-75*/ 
/*LN-76*/         if (token == address(0)) {
/*LN-77*/             // Withdraw ETH
/*LN-78*/             payable(to).transfer(amount);
/*LN-79*/         } else {
/*LN-80*/             // Withdraw ERC20 tokens
/*LN-81*/             IERC20(token).transfer(to, amount);
/*LN-82*/         }
/*LN-83*/ 
/*LN-84*/         emit Withdrawal(token, to, amount);
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     /**
/*LN-88*/      * @dev Emergency withdrawal - same vulnerability as regular withdraw
/*LN-89*/      */
/*LN-90*/     function emergencyWithdraw(address token) external onlyOwner {
/*LN-91*/         // VULNERABILITY 10: Emergency function has same weak access control
/*LN-92*/ 
/*LN-93*/         uint256 balance;
/*LN-94*/         if (token == address(0)) {
/*LN-95*/             balance = address(this).balance;
/*LN-96*/             payable(owner).transfer(balance);
/*LN-97*/         } else {
/*LN-98*/             balance = IERC20(token).balanceOf(address(this));
/*LN-99*/             IERC20(token).transfer(owner, balance);
/*LN-100*/         }
/*LN-101*/ 
/*LN-102*/         emit Withdrawal(token, owner, balance);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     /**
/*LN-106*/      * @dev Transfer ownership - critical function with no protection
/*LN-107*/      */
/*LN-108*/     function transferOwnership(address newOwner) external onlyOwner {
/*LN-109*/         // VULNERABILITY 11: Ownership transfer has no timelock
/*LN-110*/         // VULNERABILITY 12: No confirmation from new owner required
/*LN-111*/         owner = newOwner;
/*LN-112*/     }
/*LN-113*/ 
/*LN-114*/     receive() external payable {}
/*LN-115*/ }
/*LN-116*/ 
/*LN-117*/ /**
/*LN-118*/  * ATTACK SCENARIO:
/*LN-119*/  *
/*LN-120*/  * 1. Attacker compromises owner private key through:
/*LN-121*/  *    - Phishing attack targeting FixedFloat admin
/*LN-122*/  *    - Malware on admin's computer
/*LN-123*/  *    - Social engineering
/*LN-124*/  *
/*LN-125*/  * 2. With compromised key, attacker calls:
/*LN-126*/  *    hotWallet.withdraw(WBTC_ADDRESS, attackerAddress, balance)
/*LN-127*/  *    hotWallet.withdraw(address(0), attackerAddress, ethBalance)
/*LN-128*/  *
/*LN-129*/  * 3. Funds transferred immediately with no delays:
/*LN-130*/  *    - ~$15M in Bitcoin
/*LN-131*/  *    - ~$11M in Ethereum
/*LN-132*/  *
/*LN-133*/  * 4. Attacker routes funds through mixers to obfuscate trail
/*LN-134*/  *
/*LN-135*/  * 5. No recovery possible due to irreversibility of blockchain transactions
/*LN-136*/  *
/*LN-137*/  * MITIGATION STRATEGIES:
/*LN-138*/  *
/*LN-139*/  * 1. Multi-Signature Wallet:
/*LN-140*/  *    - Require 3-of-5 or 4-of-7 signatures for withdrawals
/*LN-141*/  *    - Distribute keys across different individuals/locations
/*LN-142*/  *
/*LN-143*/  * 2. Timelock Mechanism:
/*LN-144*/  *    - Add 24-48 hour delay for large withdrawals
/*LN-145*/  *    - Allow time for detection and intervention
/*LN-146*/  *
/*LN-147*/  * 3. Withdrawal Limits:
/*LN-148*/  *    - Implement daily/hourly withdrawal caps
/*LN-149*/  *    - Require additional approvals for amounts exceeding limits
/*LN-150*/  *
/*LN-151*/  * 4. Hardware Security Modules (HSM):
/*LN-152*/  *    - Store private keys in dedicated hardware
/*LN-153*/  *    - Prevent key extraction even if system compromised
/*LN-154*/  *
/*LN-155*/  * 5. Monitoring and Alerts:
/*LN-156*/  *    - Real-time monitoring of large withdrawals
/*LN-157*/  *    - Automatic alerts to multiple team members
/*LN-158*/  *    - Pause mechanism for suspicious activity
/*LN-159*/  *
/*LN-160*/  * 6. Cold Storage:
/*LN-161*/  *    - Keep majority of funds in cold wallets
/*LN-162*/  *    - Hot wallets hold only operational amounts
/*LN-163*/  *
/*LN-164*/  * 7. Key Rotation:
/*LN-165*/  *    - Regular rotation of private keys
/*LN-166*/  *    - Limit exposure window if key compromised
/*LN-167*/  *
/*LN-168*/  * 8. Access Control:
/*LN-169*/  *    - Role-based permissions
/*LN-170*/  *    - Separation of duties
/*LN-171*/  *    - No single person has complete control
/*LN-172*/  */
/*LN-173*/ 