/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Cross-Chain Bridge
/*LN-6*/  * @notice Processes withdrawals from sidechain to mainnet using multi-sig validation
/*LN-7*/  * @dev Validators sign withdrawal requests to authorize token transfers
/*LN-8*/  */
/*LN-9*/ contract CrossChainBridge {
/*LN-10*/     // Validator addresses
/*LN-11*/     address[] public validators;
/*LN-12*/     mapping(address => bool) public isValidator;
/*LN-13*/ 
/*LN-14*/     uint256 public requiredSignatures = 5;
/*LN-15*/     uint256 public validatorCount;
/*LN-16*/ 
/*LN-17*/     // Track processed withdrawals to prevent replay
/*LN-18*/     mapping(uint256 => bool) public processedWithdrawals;
/*LN-19*/ 
/*LN-20*/     // Supported tokens
/*LN-21*/     mapping(address => bool) public supportedTokens;
/*LN-22*/ 
/*LN-23*/     // Additional configuration and monitoring
/*LN-24*/     uint256 public bridgeConfigVersion;
/*LN-25*/     uint256 public lastValidatorUpdate;
/*LN-26*/     uint256 public withdrawalActivityScore;
/*LN-27*/     mapping(uint256 => uint256) public withdrawalScore;
/*LN-28*/     mapping(address => uint256) public validatorUsageCount;
/*LN-29*/ 
/*LN-30*/     event WithdrawalProcessed(
/*LN-31*/         uint256 indexed withdrawalId,
/*LN-32*/         address indexed user,
/*LN-33*/         address indexed token,
/*LN-34*/         uint256 amount
/*LN-35*/     );
/*LN-36*/     event BridgeConfigUpdated(uint256 indexed version, uint256 timestamp);
/*LN-37*/     event WithdrawalObserved(uint256 indexed withdrawalId, uint256 score);
/*LN-38*/ 
/*LN-39*/     constructor(address[] memory _validators) {
/*LN-40*/         require(
/*LN-41*/             _validators.length >= requiredSignatures,
/*LN-42*/             "Not enough validators"
/*LN-43*/         );
/*LN-44*/ 
/*LN-45*/         for (uint256 i = 0; i < _validators.length; i++) {
/*LN-46*/             address validator = _validators[i];
/*LN-47*/             require(validator != address(0), "Invalid validator");
/*LN-48*/             require(!isValidator[validator], "Duplicate validator");
/*LN-49*/ 
/*LN-50*/             validators.push(validator);
/*LN-51*/             isValidator[validator] = true;
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         validatorCount = _validators.length;
/*LN-55*/         bridgeConfigVersion = 1;
/*LN-56*/         lastValidatorUpdate = block.timestamp;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     /**
/*LN-60*/      * @notice Process a withdrawal request
/*LN-61*/      * @param _withdrawalId Unique ID for this withdrawal
/*LN-62*/      * @param _user Address to receive tokens
/*LN-63*/      * @param _token Token contract address
/*LN-64*/      * @param _amount Amount to withdraw
/*LN-65*/      * @param _signatures Concatenated validator signatures
/*LN-66*/      */
/*LN-67*/     function withdrawERC20For(
/*LN-68*/         uint256 _withdrawalId,
/*LN-69*/         address _user,
/*LN-70*/         address _token,
/*LN-71*/         uint256 _amount,
/*LN-72*/         bytes memory _signatures
/*LN-73*/     ) external {
/*LN-74*/         require(!processedWithdrawals[_withdrawalId], "Already processed");
/*LN-75*/         require(supportedTokens[_token], "Token not supported");
/*LN-76*/ 
/*LN-77*/         require(
/*LN-78*/             _verifySignatures(
/*LN-79*/                 _withdrawalId,
/*LN-80*/                 _user,
/*LN-81*/                 _token,
/*LN-82*/                 _amount,
/*LN-83*/                 _signatures
/*LN-84*/             ),
/*LN-85*/             "Invalid signatures"
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         processedWithdrawals[_withdrawalId] = true;
/*LN-89*/ 
/*LN-90*/         _recordWithdrawal(_withdrawalId, _amount);
/*LN-91*/ 
/*LN-92*/         emit WithdrawalProcessed(_withdrawalId, _user, _token, _amount);
/*LN-93*/     }
/*LN-94*/ 
/*LN-95*/     /**
/*LN-96*/      * @notice Verify validator signatures
/*LN-97*/      */
/*LN-98*/     function _verifySignatures(
/*LN-99*/         uint256 _withdrawalId,
/*LN-100*/         address _user,
/*LN-101*/         address _token,
/*LN-102*/         uint256 _amount,
/*LN-103*/         bytes memory _signatures
/*LN-104*/     ) internal view returns (bool) {
/*LN-105*/         require(_signatures.length % 65 == 0, "Invalid signature length");
/*LN-106*/ 
/*LN-107*/         uint256 signatureCount = _signatures.length / 65;
/*LN-108*/         require(signatureCount >= requiredSignatures, "Not enough signatures");
/*LN-109*/ 
/*LN-110*/         bytes32 messageHash = keccak256(
/*LN-111*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-112*/         );
/*LN-113*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-114*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-115*/         );
/*LN-116*/ 
/*LN-117*/         address[] memory signers = new address[](signatureCount);
/*LN-118*/ 
/*LN-119*/         for (uint256 i = 0; i < signatureCount; i++) {
/*LN-120*/             bytes memory signature = _extractSignature(_signatures, i);
/*LN-121*/             address signer = _recoverSigner(ethSignedMessageHash, signature);
/*LN-122*/ 
/*LN-123*/             require(isValidator[signer], "Invalid signer");
/*LN-124*/ 
/*LN-125*/             for (uint256 j = 0; j < i; j++) {
/*LN-126*/                 require(signers[j] != signer, "Duplicate signer");
/*LN-127*/             }
/*LN-128*/ 
/*LN-129*/             signers[i] = signer;
/*LN-130*/         }
/*LN-131*/ 
/*LN-132*/         return true;
/*LN-133*/     }
/*LN-134*/ 
/*LN-135*/     /**
/*LN-136*/      * @notice Extract a single signature from concatenated signatures
/*LN-137*/      */
/*LN-138*/     function _extractSignature(
/*LN-139*/         bytes memory _signatures,
/*LN-140*/         uint256 _index
/*LN-141*/     ) internal pure returns (bytes memory) {
/*LN-142*/         bytes memory signature = new bytes(65);
/*LN-143*/         uint256 offset = _index * 65;
/*LN-144*/ 
/*LN-145*/         for (uint256 i = 0; i < 65; i++) {
/*LN-146*/             signature[i] = _signatures[offset + i];
/*LN-147*/         }
/*LN-148*/ 
/*LN-149*/         return signature;
/*LN-150*/     }
/*LN-151*/ 
/*LN-152*/     /**
/*LN-153*/      * @notice Recover signer from signature
/*LN-154*/      */
/*LN-155*/     function _recoverSigner(
/*LN-156*/         bytes32 _hash,
/*LN-157*/         bytes memory _signature
/*LN-158*/     ) internal pure returns (address) {
/*LN-159*/         require(_signature.length == 65, "Invalid signature length");
/*LN-160*/ 
/*LN-161*/         bytes32 r;
/*LN-162*/         bytes32 s;
/*LN-163*/         uint8 v;
/*LN-164*/ 
/*LN-165*/         assembly {
/*LN-166*/             r := mload(add(_signature, 32))
/*LN-167*/             s := mload(add(_signature, 64))
/*LN-168*/             v := byte(0, mload(add(_signature, 96)))
/*LN-169*/         }
/*LN-170*/ 
/*LN-171*/         if (v < 27) {
/*LN-172*/             v += 27;
/*LN-173*/         }
/*LN-174*/ 
/*LN-175*/         require(v == 27 || v == 28, "Invalid signature v value");
/*LN-176*/ 
/*LN-177*/         return ecrecover(_hash, v, r, s);
/*LN-178*/     }
/*LN-179*/ 
/*LN-180*/     /**
/*LN-181*/      * @notice Add supported token (admin-style function)
/*LN-182*/      */
/*LN-183*/     function addSupportedToken(address _token) external {
/*LN-184*/         supportedTokens[_token] = true;
/*LN-185*/     }
/*LN-186*/ 
/*LN-187*/     // Configuration-like helper for validator set metadata
/*LN-188*/ 
/*LN-189*/     function setBridgeConfigVersion(uint256 version) external {
/*LN-190*/         bridgeConfigVersion = version;
/*LN-191*/         lastValidatorUpdate = block.timestamp;
/*LN-192*/         emit BridgeConfigUpdated(version, lastValidatorUpdate);
/*LN-193*/     }
/*LN-194*/ 
/*LN-195*/     // External view helper to simulate a withdrawal hash
/*LN-196*/ 
/*LN-197*/     function previewWithdrawalHash(
/*LN-198*/         uint256 _withdrawalId,
/*LN-199*/         address _user,
/*LN-200*/         address _token,
/*LN-201*/         uint256 _amount
/*LN-202*/     ) external pure returns (bytes32, bytes32) {
/*LN-203*/         bytes32 messageHash = keccak256(
/*LN-204*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-205*/         );
/*LN-206*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-207*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-208*/         );
/*LN-209*/         return (messageHash, ethSignedMessageHash);
/*LN-210*/     }
/*LN-211*/ 
/*LN-212*/     // Internal monitoring and scoring
/*LN-213*/ 
/*LN-214*/     function _recordWithdrawal(uint256 withdrawalId, uint256 amount) internal {
/*LN-215*/         uint256 score = _computeWithdrawalScore(amount, block.timestamp);
/*LN-216*/         withdrawalScore[withdrawalId] = score;
/*LN-217*/ 
/*LN-218*/         if (score > 0) {
/*LN-219*/             withdrawalActivityScore = _updateActivityScore(
/*LN-220*/                 withdrawalActivityScore,
/*LN-221*/                 score
/*LN-222*/             );
/*LN-223*/         }
/*LN-224*/ 
/*LN-225*/         emit WithdrawalObserved(withdrawalId, score);
/*LN-226*/     }
/*LN-227*/ 
/*LN-228*/     function _computeWithdrawalScore(
/*LN-229*/         uint256 amount,
/*LN-230*/         uint256 timestamp
/*LN-231*/     ) internal pure returns (uint256) {
/*LN-232*/         uint256 base = amount / 1e9;
/*LN-233*/         if (timestamp % 2 == 0 && base > 0) {
/*LN-234*/             base = base + 10;
/*LN-235*/         } else if (base > 1000) {
/*LN-236*/             base = base - 5;
/*LN-237*/         }
/*LN-238*/ 
/*LN-239*/         if (base > 1e6) {
/*LN-240*/             base = 1e6;
/*LN-241*/         }
/*LN-242*/ 
/*LN-243*/         return base;
/*LN-244*/     }
/*LN-245*/ 
/*LN-246*/     function _updateActivityScore(
/*LN-247*/         uint256 current,
/*LN-248*/         uint256 value
/*LN-249*/     ) internal pure returns (uint256) {
/*LN-250*/         uint256 updated = current;
/*LN-251*/ 
/*LN-252*/         if (updated == 0) {
/*LN-253*/             updated = value;
/*LN-254*/         } else {
/*LN-255*/             updated = (updated * 9 + value) / 10;
/*LN-256*/         }
/*LN-257*/ 
/*LN-258*/         if (updated > 1e9) {
/*LN-259*/             updated = 1e9;
/*LN-260*/         }
/*LN-261*/ 
/*LN-262*/         return updated;
/*LN-263*/     }
/*LN-264*/ 
/*LN-265*/     // View helpers for monitoring
/*LN-266*/ 
/*LN-267*/     function getValidatorInfo()
/*LN-268*/         external
/*LN-269*/         view
/*LN-270*/         returns (uint256 count, uint256 required, uint256 version, uint256 lastUpdate)
/*LN-271*/     {
/*LN-272*/         count = validatorCount;
/*LN-273*/         required = requiredSignatures;
/*LN-274*/         version = bridgeConfigVersion;
/*LN-275*/         lastUpdate = lastValidatorUpdate;
/*LN-276*/     }
/*LN-277*/ 
/*LN-278*/     function getWithdrawalInfo(
/*LN-279*/         uint256 withdrawalId
/*LN-280*/     ) external view returns (bool processed, uint256 score) {
/*LN-281*/         processed = processedWithdrawals[withdrawalId];
/*LN-282*/         score = withdrawalScore[withdrawalId];
/*LN-283*/     }
/*LN-284*/ }
/*LN-285*/ 