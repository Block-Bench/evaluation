/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Ronin Bridge (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the multi-sig vulnerability that led to the $625M Ronin Bridge hack
/*LN-7*/  * @dev March 23, 2022 - Largest bridge hack in crypto history
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Compromised validator keys / insufficient decentralization
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The Ronin Bridge used a multi-signature system with 9 validators. To process
/*LN-13*/  * a withdrawal, 5 out of 9 validator signatures were required. However:
/*LN-14*/  *
/*LN-15*/  * 1. Sky Mavis (Axie Infinity creator) controlled 4 validator nodes
/*LN-16*/  * 2. One validator was run by a DAO, but Sky Mavis had access to it
/*LN-17*/  * 3. Attackers compromised Sky Mavis's infrastructure
/*LN-18*/  * 4. Gained access to 5 out of 9 validator keys
/*LN-19*/  * 5. Could forge valid signatures for any withdrawal
/*LN-20*/  *
/*LN-21*/  * The root issue was insufficient decentralization - a single entity controlled
/*LN-22*/  * enough validators to approve withdrawals unilaterally.
/*LN-23*/  *
/*LN-24*/  * ATTACK VECTOR:
/*LN-25*/  * 1. Attackers compromised Sky Mavis's systems (possibly via social engineering)
/*LN-26*/  * 2. Gained access to private keys for 4 Sky Mavis validators
/*LN-27*/  * 3. Gained access to 1 DAO validator key (Sky Mavis had temporary access)
/*LN-28*/  * 4. Now controlled 5/9 validators - enough to approve withdrawals
/*LN-29*/  * 5. Created fake withdrawal requests with forged signatures
/*LN-30*/  * 6. Bridge contract verified signatures (all valid!)
/*LN-31*/  * 7. Bridge transferred $625M in ETH and USDC to attacker
/*LN-32*/  *
/*LN-33*/  * This demonstrates that multi-sig security depends entirely on:
/*LN-34*/  * - Key management
/*LN-35*/  * - Distribution of control
/*LN-36*/  * - Infrastructure security
/*LN-37*/  */
/*LN-38*/ 
/*LN-39*/ contract VulnerableRoninBridge {
/*LN-40*/     // Validator addresses
/*LN-41*/     address[] public validators;
/*LN-42*/     mapping(address => bool) public isValidator;
/*LN-43*/ 
/*LN-44*/     uint256 public requiredSignatures = 5; // Need 5 out of 9
/*LN-45*/     uint256 public validatorCount;
/*LN-46*/ 
/*LN-47*/     // Track processed withdrawals to prevent replay
/*LN-48*/     mapping(uint256 => bool) public processedWithdrawals;
/*LN-49*/ 
/*LN-50*/     // Supported tokens
/*LN-51*/     mapping(address => bool) public supportedTokens;
/*LN-52*/ 
/*LN-53*/     event WithdrawalProcessed(
/*LN-54*/         uint256 indexed withdrawalId,
/*LN-55*/         address indexed user,
/*LN-56*/         address indexed token,
/*LN-57*/         uint256 amount
/*LN-58*/     );
/*LN-59*/ 
/*LN-60*/     constructor(address[] memory _validators) {
/*LN-61*/         require(
/*LN-62*/             _validators.length >= requiredSignatures,
/*LN-63*/             "Not enough validators"
/*LN-64*/         );
/*LN-65*/ 
/*LN-66*/         for (uint256 i = 0; i < _validators.length; i++) {
/*LN-67*/             address validator = _validators[i];
/*LN-68*/             require(validator != address(0), "Invalid validator");
/*LN-69*/             require(!isValidator[validator], "Duplicate validator");
/*LN-70*/ 
/*LN-71*/             validators.push(validator);
/*LN-72*/             isValidator[validator] = true;
/*LN-73*/         }
/*LN-74*/ 
/*LN-75*/         validatorCount = _validators.length;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     /**
/*LN-79*/      * @notice Process a withdrawal from Ronin to Ethereum
/*LN-80*/      * @param _withdrawalId Unique ID for this withdrawal
/*LN-81*/      * @param _user Address to receive tokens
/*LN-82*/      * @param _token Token contract address
/*LN-83*/      * @param _amount Amount to withdraw
/*LN-84*/      * @param _signatures Concatenated validator signatures
/*LN-85*/      *
/*LN-86*/      * VULNERABILITY:
/*LN-87*/      * While the signature verification logic is correct, the vulnerability
/*LN-88*/      * lies in the validator key management. If an attacker gains control of
/*LN-89*/      * >= 5 validator private keys, they can forge valid signatures for any
/*LN-90*/      * withdrawal, even ones that never happened on Ronin chain.
/*LN-91*/      *
/*LN-92*/      * In the Ronin hack:
/*LN-93*/      * - Sky Mavis controlled 4 validators
/*LN-94*/      * - DAO validator was temporarily managed by Sky Mavis (5th key)
/*LN-95*/      * - Attackers compromised Sky Mavis infrastructure
/*LN-96*/      * - Gained access to all 5 keys
/*LN-97*/      * - Created fake withdrawals with valid signatures
/*LN-98*/      */
/*LN-99*/     function withdrawERC20For(
/*LN-100*/         uint256 _withdrawalId,
/*LN-101*/         address _user,
/*LN-102*/         address _token,
/*LN-103*/         uint256 _amount,
/*LN-104*/         bytes memory _signatures
/*LN-105*/     ) external {
/*LN-106*/         // Check if already processed
/*LN-107*/         require(!processedWithdrawals[_withdrawalId], "Already processed");
/*LN-108*/ 
/*LN-109*/         // Check if token is supported
/*LN-110*/         require(supportedTokens[_token], "Token not supported");
/*LN-111*/ 
/*LN-112*/         // Verify signatures
/*LN-113*/         // VULNERABILITY: If enough validator keys are compromised,
/*LN-114*/         // attackers can create valid signatures for fake withdrawals
/*LN-115*/         require(
/*LN-116*/             _verifySignatures(
/*LN-117*/                 _withdrawalId,
/*LN-118*/                 _user,
/*LN-119*/                 _token,
/*LN-120*/                 _amount,
/*LN-121*/                 _signatures
/*LN-122*/             ),
/*LN-123*/             "Invalid signatures"
/*LN-124*/         );
/*LN-125*/ 
/*LN-126*/         // Mark as processed
/*LN-127*/         processedWithdrawals[_withdrawalId] = true;
/*LN-128*/ 
/*LN-129*/         // Transfer tokens
/*LN-130*/         // In reality, this would transfer from bridge reserves
/*LN-131*/         // IERC20(_token).transfer(_user, _amount);
/*LN-132*/ 
/*LN-133*/         emit WithdrawalProcessed(_withdrawalId, _user, _token, _amount);
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     /**
/*LN-137*/      * @notice Verify validator signatures
/*LN-138*/      * @dev VULNERABILITY: The verification logic is correct, but useless if
/*LN-139*/      * validator keys are compromised. The attacker had valid keys, so they
/*LN-140*/      * could create genuinely valid signatures for fake withdrawals.
/*LN-141*/      */
/*LN-142*/     function _verifySignatures(
/*LN-143*/         uint256 _withdrawalId,
/*LN-144*/         address _user,
/*LN-145*/         address _token,
/*LN-146*/         uint256 _amount,
/*LN-147*/         bytes memory _signatures
/*LN-148*/     ) internal view returns (bool) {
/*LN-149*/         require(_signatures.length % 65 == 0, "Invalid signature length");
/*LN-150*/ 
/*LN-151*/         uint256 signatureCount = _signatures.length / 65;
/*LN-152*/         require(signatureCount >= requiredSignatures, "Not enough signatures");
/*LN-153*/ 
/*LN-154*/         // Reconstruct the message hash
/*LN-155*/         bytes32 messageHash = keccak256(
/*LN-156*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-157*/         );
/*LN-158*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-159*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-160*/         );
/*LN-161*/ 
/*LN-162*/         address[] memory signers = new address[](signatureCount);
/*LN-163*/ 
/*LN-164*/         // Extract and verify each signature
/*LN-165*/         for (uint256 i = 0; i < signatureCount; i++) {
/*LN-166*/             bytes memory signature = _extractSignature(_signatures, i);
/*LN-167*/             address signer = _recoverSigner(ethSignedMessageHash, signature);
/*LN-168*/ 
/*LN-169*/             // Check if signer is a validator
/*LN-170*/             require(isValidator[signer], "Invalid signer");
/*LN-171*/ 
/*LN-172*/             // Check for duplicate signers
/*LN-173*/             for (uint256 j = 0; j < i; j++) {
/*LN-174*/                 require(signers[j] != signer, "Duplicate signer");
/*LN-175*/             }
/*LN-176*/ 
/*LN-177*/             signers[i] = signer;
/*LN-178*/         }
/*LN-179*/ 
/*LN-180*/         // All checks passed
/*LN-181*/         return true;
/*LN-182*/     }
/*LN-183*/ 
/*LN-184*/     /**
/*LN-185*/      * @notice Extract a single signature from concatenated signatures
/*LN-186*/      */
/*LN-187*/     function _extractSignature(
/*LN-188*/         bytes memory _signatures,
/*LN-189*/         uint256 _index
/*LN-190*/     ) internal pure returns (bytes memory) {
/*LN-191*/         bytes memory signature = new bytes(65);
/*LN-192*/         uint256 offset = _index * 65;
/*LN-193*/ 
/*LN-194*/         for (uint256 i = 0; i < 65; i++) {
/*LN-195*/             signature[i] = _signatures[offset + i];
/*LN-196*/         }
/*LN-197*/ 
/*LN-198*/         return signature;
/*LN-199*/     }
/*LN-200*/ 
/*LN-201*/     /**
/*LN-202*/      * @notice Recover signer from signature
/*LN-203*/      */
/*LN-204*/     function _recoverSigner(
/*LN-205*/         bytes32 _hash,
/*LN-206*/         bytes memory _signature
/*LN-207*/     ) internal pure returns (address) {
/*LN-208*/         require(_signature.length == 65, "Invalid signature length");
/*LN-209*/ 
/*LN-210*/         bytes32 r;
/*LN-211*/         bytes32 s;
/*LN-212*/         uint8 v;
/*LN-213*/ 
/*LN-214*/         assembly {
/*LN-215*/             r := mload(add(_signature, 32))
/*LN-216*/             s := mload(add(_signature, 64))
/*LN-217*/             v := byte(0, mload(add(_signature, 96)))
/*LN-218*/         }
/*LN-219*/ 
/*LN-220*/         if (v < 27) {
/*LN-221*/             v += 27;
/*LN-222*/         }
/*LN-223*/ 
/*LN-224*/         require(v == 27 || v == 28, "Invalid signature v value");
/*LN-225*/ 
/*LN-226*/         return ecrecover(_hash, v, r, s);
/*LN-227*/     }
/*LN-228*/ 
/*LN-229*/     /**
/*LN-230*/      * @notice Add supported token (admin function)
/*LN-231*/      */
/*LN-232*/     function addSupportedToken(address _token) external {
/*LN-233*/         supportedTokens[_token] = true;
/*LN-234*/     }
/*LN-235*/ }
/*LN-236*/ 
/*LN-237*/ /**
/*LN-238*/  * REAL-WORLD IMPACT:
/*LN-239*/  * - $625M stolen (173,600 ETH + 25.5M USDC) on March 23, 2022
/*LN-240*/  * - Largest bridge hack in crypto history at the time
/*LN-241*/  * - Took 6 days before anyone noticed (!)
/*LN-242*/  * - Funds were never recovered
/*LN-243*/  * - Caused massive damage to Axie Infinity ecosystem
/*LN-244*/  *
/*LN-245*/  * FIX:
/*LN-246*/  * The fix requires:
/*LN-247*/  * 1. Increase total number of validators (more decentralization)
/*LN-248*/  * 2. Ensure no single entity controls multiple validators
/*LN-249*/  * 3. Implement hardware security modules (HSMs) for key storage
/*LN-250*/  * 4. Use threshold signatures (MPC) instead of multi-sig
/*LN-251*/  * 5. Implement real-time monitoring and alerts
/*LN-252*/  * 6. Add withdrawal limits and timeloacks for large amounts
/*LN-253*/  * 7. Require geographic and organizational diversity among validators
/*LN-254*/  * 8. Implement anomaly detection for unusual withdrawal patterns
/*LN-255*/  * 9. Use cold wallets with delays for large reserves
/*LN-256*/  * 10. Regular security audits and penetration testing
/*LN-257*/  *
/*LN-258*/  * KEY LESSON:
/*LN-259*/  * Multi-sig security is only as strong as the weakest validator.
/*LN-260*/  * If a single entity controls multiple validators, or if validator
/*LN-261*/  * infrastructure is not properly secured, the entire system is vulnerable.
/*LN-262*/  *
/*LN-263*/  * The Ronin hack demonstrated that:
/*LN-264*/  * - Decentralization must be real, not just on paper
/*LN-265*/  * - Key management is critical
/*LN-266*/  * - Monitoring and alerting must be robust (6 days to detect!)
/*LN-267*/  * - Bridge security is a major attack vector in DeFi
/*LN-268*/  *
/*LN-269*/  * The vulnerability wasn't in the smart contract code itself - the signature
/*LN-270*/  * verification was correct. The issue was centralization and compromised
/*LN-271*/  * infrastructure. This is a reminder that security extends beyond code.
/*LN-272*/  *
/*LN-273*/  * - The real vulnerability was in the validator setup and key management
/*LN-274*/  *
/*LN-275*/  * ATTRIBUTION:
/*LN-276*/  * The attack was attributed to the Lazarus Group (North Korean state hackers).
/*LN-277*/  * They used sophisticated social engineering and infrastructure compromise.
/*LN-278*/  */
/*LN-279*/ 