/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * MUNCHABLES EXPLOIT (March 2024)
/*LN-6*/  * Loss: $62 million (fully recovered)
/*LN-7*/  * Attack: Developer Private Key Compromise + Malicious Contract Upgrade
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY OVERVIEW:
/*LN-10*/  * Munchables, a GameFi project on Blast L2, suffered an exploit when a rogue developer
/*LN-11*/  * with access to privileged private keys upgraded contracts to malicious implementations.
/*LN-12*/  * The attacker locked user funds by setting withdrawal addresses to their own control.
/*LN-13*/  *
/*LN-14*/  * UNIQUE ASPECT: Funds were fully recovered after negotiations with the attacker,
/*LN-15*/  * who turned out to be a North Korean developer hired by the project.
/*LN-16*/  *
/*LN-17*/  * ROOT CAUSE:
/*LN-18*/  * 1. Single developer had access to critical private keys
/*LN-19*/  * 2. No multi-signature requirement for contract upgrades
/*LN-20*/  * 3. Missing timelock delay for critical operations
/*LN-21*/  * 4. Insufficient background checks on developers with key access
/*LN-22*/  * 5. No code review process for upgrades
/*LN-23*/  *
/*LN-24*/  * ATTACK FLOW:
/*LN-25*/  * 1. Rogue developer prepared malicious contract implementation
/*LN-26*/  * 2. Used admin keys to upgrade LockManager contract
/*LN-27*/  * 3. Malicious contract allowed setting arbitrary lock recipients
/*LN-28*/  * 4. Transferred all user funds to attacker-controlled addresses
/*LN-29*/  * 5. $62M in ETH/WETH locked in attacker wallets
/*LN-30*/  * 6. Project negotiated with attacker (revealed to be DPRK dev)
/*LN-31*/  * 7. Full funds returned and project resumed operations
/*LN-32*/  */
/*LN-33*/ 
/*LN-34*/ interface IERC20 {
/*LN-35*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-36*/ 
/*LN-37*/     function transferFrom(
/*LN-38*/         address from,
/*LN-39*/         address to,
/*LN-40*/         uint256 amount
/*LN-41*/     ) external returns (bool);
/*LN-42*/ 
/*LN-43*/     function balanceOf(address account) external view returns (uint256);
/*LN-44*/ }
/*LN-45*/ 
/*LN-46*/ /**
/*LN-47*/  * Munchables Lock Manager (Vulnerable Version)
/*LN-48*/  */
/*LN-49*/ contract MunchablesLockManager {
/*LN-50*/     address public admin;
/*LN-51*/     address public configStorage;
/*LN-52*/ 
/*LN-53*/     struct PlayerSettings {
/*LN-54*/         uint256 lockedAmount;
/*LN-55*/         address lockRecipient;
/*LN-56*/         uint256 lockDuration;
/*LN-57*/         uint256 lockStartTime;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     // VULNERABILITY 1: Admin has unrestricted control
/*LN-61*/     mapping(address => PlayerSettings) public playerSettings;
/*LN-62*/     mapping(address => uint256) public playerBalances;
/*LN-63*/ 
/*LN-64*/     IERC20 public immutable weth;
/*LN-65*/ 
/*LN-66*/     event Locked(address player, uint256 amount, address recipient);
/*LN-67*/     event ConfigUpdated(address oldConfig, address newConfig);
/*LN-68*/ 
/*LN-69*/     constructor(address _weth) {
/*LN-70*/         admin = msg.sender;
/*LN-71*/         weth = IERC20(_weth);
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     /**
/*LN-75*/      * @dev VULNERABILITY 2: Single admin modifier, no multi-sig
/*LN-76*/      */
/*LN-77*/     modifier onlyAdmin() {
/*LN-78*/         require(msg.sender == admin, "Not admin");
/*LN-79*/         _;
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     /**
/*LN-83*/      * @dev Users lock tokens to earn rewards
/*LN-84*/      */
/*LN-85*/     function lock(uint256 amount, uint256 duration) external {
/*LN-86*/         require(amount > 0, "Zero amount");
/*LN-87*/ 
/*LN-88*/         weth.transferFrom(msg.sender, address(this), amount);
/*LN-89*/ 
/*LN-90*/         playerBalances[msg.sender] += amount;
/*LN-91*/         playerSettings[msg.sender] = PlayerSettings({
/*LN-92*/             lockedAmount: amount,
/*LN-93*/             lockRecipient: msg.sender,
/*LN-94*/             lockDuration: duration,
/*LN-95*/             lockStartTime: block.timestamp
/*LN-96*/         });
/*LN-97*/ 
/*LN-98*/         emit Locked(msg.sender, amount, msg.sender);
/*LN-99*/     }
/*LN-100*/ 
/*LN-101*/     /**
/*LN-102*/      * @dev VULNERABILITY 3: Admin can change configStorage without restrictions
/*LN-103*/      * @dev VULNERABILITY 4: No timelock delay for critical changes
/*LN-104*/      */
/*LN-105*/     function setConfigStorage(address _configStorage) external onlyAdmin {
/*LN-106*/         // VULNERABILITY 5: Immediate execution, no delay
/*LN-107*/         address oldConfig = configStorage;
/*LN-108*/         configStorage = _configStorage;
/*LN-109*/ 
/*LN-110*/         emit ConfigUpdated(oldConfig, _configStorage);
/*LN-111*/     }
/*LN-112*/ 
/*LN-113*/     /**
/*LN-114*/      * @dev VULNERABILITY 6: Admin can modify user settings arbitrarily
/*LN-115*/      * @dev This is the key function exploited by rogue developer
/*LN-116*/      */
/*LN-117*/     function setLockRecipient(
/*LN-118*/         address player,
/*LN-119*/         address newRecipient
/*LN-120*/     ) external onlyAdmin {
/*LN-121*/         // VULNERABILITY 7: No validation of newRecipient
/*LN-122*/         // VULNERABILITY 8: Can redirect all user funds to attacker
/*LN-123*/         // VULNERABILITY 9: No user consent required
/*LN-124*/ 
/*LN-125*/         playerSettings[player].lockRecipient = newRecipient;
/*LN-126*/     }
/*LN-127*/ 
/*LN-128*/     /**
/*LN-129*/      * @dev Unlock funds after lock period expires
/*LN-130*/      */
/*LN-131*/     function unlock() external {
/*LN-132*/         PlayerSettings memory settings = playerSettings[msg.sender];
/*LN-133*/ 
/*LN-134*/         require(settings.lockedAmount > 0, "No locked tokens");
/*LN-135*/         require(
/*LN-136*/             block.timestamp >= settings.lockStartTime + settings.lockDuration,
/*LN-137*/             "Still locked"
/*LN-138*/         );
/*LN-139*/ 
/*LN-140*/         uint256 amount = settings.lockedAmount;
/*LN-141*/ 
/*LN-142*/         // VULNERABILITY 10: Funds sent to potentially attacker-controlled recipient
/*LN-143*/         address recipient = settings.lockRecipient;
/*LN-144*/ 
/*LN-145*/         delete playerSettings[msg.sender];
/*LN-146*/         playerBalances[msg.sender] = 0;
/*LN-147*/ 
/*LN-148*/         weth.transfer(recipient, amount);
/*LN-149*/     }
/*LN-150*/ 
/*LN-151*/     /**
/*LN-152*/      * @dev VULNERABILITY 11: Emergency withdrawal also uses lockRecipient
/*LN-153*/      */
/*LN-154*/     function emergencyUnlock(address player) external onlyAdmin {
/*LN-155*/         PlayerSettings memory settings = playerSettings[player];
/*LN-156*/         uint256 amount = settings.lockedAmount;
/*LN-157*/         address recipient = settings.lockRecipient;
/*LN-158*/ 
/*LN-159*/         delete playerSettings[player];
/*LN-160*/         playerBalances[player] = 0;
/*LN-161*/ 
/*LN-162*/         // Sends to whoever admin set as lockRecipient
/*LN-163*/         weth.transfer(recipient, amount);
/*LN-164*/     }
/*LN-165*/ 
/*LN-166*/     /**
/*LN-167*/      * @dev VULNERABILITY 12: Admin transfer with no restrictions
/*LN-168*/      */
/*LN-169*/     function transferAdmin(address newAdmin) external onlyAdmin {
/*LN-170*/         // VULNERABILITY 13: No timelock, no multi-sig confirmation
/*LN-171*/         admin = newAdmin;
/*LN-172*/     }
/*LN-173*/ }
/*LN-174*/ 
/*LN-175*/ /**
/*LN-176*/  * ATTACK SCENARIO:
/*LN-177*/  *
/*LN-178*/  * Preparation Phase:
/*LN-179*/  * 1. Rogue developer (later revealed as North Korean operative) gains employment
/*LN-180*/  * 2. Developer given access to admin private keys for "development purposes"
/*LN-181*/  * 3. Project has ~$62M in user deposits locked in contracts
/*LN-182*/  *
/*LN-183*/  * Exploitation Phase (March 26, 2024):
/*LN-184*/  *
/*LN-185*/  * Step 1: Upgrade to Malicious Implementation
/*LN-186*/  * - Developer uses admin key to upgrade LockManager to malicious version
/*LN-187*/  * - Malicious version allows arbitrary setLockRecipient calls
/*LN-188*/  *
/*LN-189*/  * Step 2: Redirect All User Funds
/*LN-190*/  * - For each user with locked funds:
/*LN-191*/  *   setLockRecipient(user, attackerWallet)
/*LN-192*/  *
/*LN-193*/  * Step 3: Trigger Emergency Unlocks
/*LN-194*/  * - Call emergencyUnlock() for all users
/*LN-195*/  * - Funds flow to attacker's lockRecipient addresses
/*LN-196*/  * - Total drained: $62M in ETH/WETH
/*LN-197*/  *
/*LN-198*/  * Step 4: Transfer to External Wallets
/*LN-199*/  * - Attacker moves funds across multiple wallets
/*LN-200*/  * - Prepares for mixing/laundering
/*LN-201*/  *
/*LN-202*/  * Recovery Phase (Unusual Outcome):
/*LN-203*/  *
/*LN-204*/  * 1. Munchables team traces attacker identity
/*LN-205*/  * 2. Discovers attacker is DPRK-linked developer
/*LN-206*/  * 3. Opens negotiations through intermediaries
/*LN-207*/  * 4. Attacker agrees to return all funds (reasons unclear)
/*LN-208*/  * 5. All $62M returned to project
/*LN-209*/  * 6. Project compensates affected users
/*LN-210*/  * 7. Upgrades security and continues operations
/*LN-211*/  *
/*LN-212*/  * MITIGATION STRATEGIES:
/*LN-213*/  *
/*LN-214*/  * 1. Multi-Signature Requirements:
/*LN-215*/  *    // Require 3-of-5 signatures for admin actions
/*LN-216*/  *    modifier onlyMultiSig() {
/*LN-217*/  *        require(multiSig.isConfirmed(msg.data), "Not confirmed");
/*LN-218*/  *        _;
/*LN-219*/  *    }
/*LN-220*/  *
/*LN-221*/  * 2. Timelock Delays:
/*LN-222*/  *    uint256 public constant ADMIN_DELAY = 48 hours;
/*LN-223*/  *    mapping(bytes32 => uint256) public scheduledActions;
/*LN-224*/  *
/*LN-225*/  *    function scheduleSetRecipient(...) external onlyAdmin {
/*LN-226*/  *        bytes32 actionHash = keccak256(abi.encode(...));
/*LN-227*/  *        scheduledActions[actionHash] = block.timestamp + ADMIN_DELAY;
/*LN-228*/  *    }
/*LN-229*/  *
/*LN-230*/  * 3. User Consent Required:
/*LN-231*/  *    function setLockRecipient(address newRecipient) external {
/*LN-232*/  *        // Only users can change their own recipient
/*LN-233*/  *        require(msg.sender == player, "Only user");
/*LN-234*/  *        playerSettings[msg.sender].lockRecipient = newRecipient;
/*LN-235*/  *    }
/*LN-236*/  *
/*LN-237*/  * 4. Immutable Critical Functions:
/*LN-238*/  *    // Remove admin override capabilities
/*LN-239*/  *    // Users have full control of their funds
/*LN-240*/  *
/*LN-241*/  * 5. Developer Vetting:
/*LN-242*/  *    - Thorough background checks
/*LN-243*/  *    - Principle of least privilege
/*LN-244*/  *    - No single person has critical key access
/*LN-245*/  *
/*LN-246*/  * 6. Code Review Process:
/*LN-247*/  *    - All upgrades reviewed by multiple team members
/*LN-248*/  *    - External audit before deployment
/*LN-249*/  *    - Community governance for changes
/*LN-250*/  *
/*LN-251*/  * 7. Hardware Security:
/*LN-252*/  *    - Admin keys stored in HSMs
/*LN-253*/  *    - Physical presence required
/*LN-254*/  *    - Geographic distribution
/*LN-255*/  *
/*LN-256*/  * 8. Monitoring and Alerts:
/*LN-257*/  *    - Real-time alerts on admin actions
/*LN-258*/  *    - Automatic pause on suspicious activity
/*LN-259*/  *    - Community oversight dashboard
/*LN-260*/  *
/*LN-261*/  * 9. Gradual Privilege Escalation:
/*LN-262*/  *    - New developers start with limited access
/*LN-263*/  *    - Increase privileges over time with trust
/*LN-264*/  *    - Regular security training
/*LN-265*/  *
/*LN-266*/  * 10. Decentralized Governance:
/*LN-267*/  *     - Move to DAO-controlled upgrades
/*LN-268*/  *     - Token holder voting
/*LN-269*/  *     - Eliminate single points of failure
/*LN-270*/  */
/*LN-271*/ 