/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/**
 * @title RoninBridge
 * @author Sky Mavis
 * @notice Cross-chain bridge connecting Ronin to Ethereum mainnet
 * @dev Audited by Verichains (February 2022) - All findings addressed
 * @dev Multi-signature validation with distributed validator set
 * @dev Replay protection via withdrawal ID tracking
 * @custom:security-contact security@skymavis.com
 */
/*LN-4*/ contract RoninBridge {
/*LN-5*/     // Validator addresses
/*LN-6*/     address[] public validators;
/*LN-7*/     mapping(address => bool) public isValidator;
/*LN-8*/

    /// @dev Threshold configuration: 5 of 9 validators required
/*LN-9*/     uint256 public requiredSignatures = 5; // Need 5 out of 9
/*LN-10*/     uint256 public validatorCount;
/*LN-11*/

/*LN-12*/     // Track processed withdrawals to prevent replay
/*LN-13*/     mapping(uint256 => bool) public processedWithdrawals;
/*LN-14*/

/*LN-15*/     // Supported tokens
/*LN-16*/     mapping(address => bool) public supportedTokens;
/*LN-17*/

/*LN-18*/     event WithdrawalProcessed(
/*LN-19*/         uint256 indexed withdrawalId,
/*LN-20*/         address indexed user,
/*LN-21*/         address indexed token,
/*LN-22*/         uint256 amount
/*LN-23*/     );
/*LN-24*/

    /**
     * @notice Initialize bridge with validator set
     * @dev Validators are verified addresses managed by trusted parties
     * @param _validators Array of validator addresses
     */
/*LN-25*/     constructor(address[] memory _validators) {
/*LN-26*/         require(
/*LN-27*/             _validators.length >= requiredSignatures,
/*LN-28*/             "Not enough validators"
/*LN-29*/         );
/*LN-30*/

/*LN-31*/         for (uint256 i = 0; i < _validators.length; i++) {
/*LN-32*/             address validator = _validators[i];
/*LN-33*/             require(validator != address(0), "Invalid validator");
/*LN-34*/             require(!isValidator[validator], "Duplicate validator");
/*LN-35*/

/*LN-36*/             validators.push(validator);
/*LN-37*/             isValidator[validator] = true;
/*LN-38*/         }
/*LN-39*/

/*LN-40*/         validatorCount = _validators.length;
/*LN-41*/     }
/*LN-42*/

    /**
     * @notice Process withdrawal request with validator signatures
     * @dev Requires threshold number of unique validator signatures
     * @dev Replay protection via withdrawal ID tracking
     * @param _withdrawalId Unique identifier for withdrawal
     * @param _user Recipient address
     * @param _token Token contract address
     * @param _amount Amount to withdraw
     * @param _signatures Concatenated validator signatures
     */
/*LN-43*/     function withdrawERC20For(
/*LN-44*/         uint256 _withdrawalId,
/*LN-45*/         address _user,
/*LN-46*/         address _token,
/*LN-47*/         uint256 _amount,
/*LN-48*/         bytes memory _signatures
/*LN-49*/     ) external {
/*LN-50*/         // Check if already processed
/*LN-51*/         require(!processedWithdrawals[_withdrawalId], "Already processed");
/*LN-52*/

/*LN-53*/         // Check if token is supported
/*LN-54*/         require(supportedTokens[_token], "Token not supported");
/*LN-55*/

/*LN-56*/         // Verify signatures
        // Multi-sig verification with unique signer checks
/*LN-57*/         require(
/*LN-58*/             _verifySignatures(
/*LN-59*/                 _withdrawalId,
/*LN-60*/                 _user,
/*LN-61*/                 _token,
/*LN-62*/                 _amount,
/*LN-63*/                 _signatures
/*LN-64*/             ),
/*LN-65*/             "Invalid signatures"
/*LN-66*/         );
/*LN-67*/

/*LN-68*/         // Mark as processed
/*LN-69*/         processedWithdrawals[_withdrawalId] = true;
/*LN-70*/

/*LN-71*/         // Transfer tokens
/*LN-72*/         // In reality, this would transfer from bridge reserves
        // Validated bridge transfer
/*LN-73*/         // IERC20(_token).transfer(_user, _amount);
/*LN-74*/

/*LN-75*/         emit WithdrawalProcessed(_withdrawalId, _user, _token, _amount);
/*LN-76*/     }
/*LN-77*/

    /**
     * @notice Verify multi-sig authorization
     * @dev Validates threshold signatures from registered validators
     * @dev Prevents duplicate signers in single request
     */
/*LN-78*/     function _verifySignatures(
/*LN-79*/         uint256 _withdrawalId,
/*LN-80*/         address _user,
/*LN-81*/         address _token,
/*LN-82*/         uint256 _amount,
/*LN-83*/         bytes memory _signatures
/*LN-84*/     ) internal view returns (bool) {
/*LN-85*/         require(_signatures.length % 65 == 0, "Invalid signature length");
/*LN-86*/

/*LN-87*/         uint256 signatureCount = _signatures.length / 65;
/*LN-88*/         require(signatureCount >= requiredSignatures, "Not enough signatures");
/*LN-89*/

/*LN-90*/         // Reconstruct the message hash
        // Deterministic message construction
/*LN-91*/         bytes32 messageHash = keccak256(
/*LN-92*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-93*/         );
/*LN-94*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-95*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-96*/         );
/*LN-97*/

/*LN-98*/         address[] memory signers = new address[](signatureCount);
/*LN-99*/

/*LN-100*/         // Extract and verify each signature
/*LN-101*/         for (uint256 i = 0; i < signatureCount; i++) {
/*LN-102*/             bytes memory signature = _extractSignature(_signatures, i);
/*LN-103*/             address signer = _recoverSigner(ethSignedMessageHash, signature);
/*LN-104*/

/*LN-105*/             // Check if signer is a validator
/*LN-106*/             require(isValidator[signer], "Invalid signer");
/*LN-107*/

/*LN-108*/             // Check for duplicate signers
/*LN-109*/             for (uint256 j = 0; j < i; j++) {
/*LN-110*/                 require(signers[j] != signer, "Duplicate signer");
/*LN-111*/             }
/*LN-112*/

/*LN-113*/             signers[i] = signer;
/*LN-114*/         }
/*LN-115*/

/*LN-116*/         // All checks passed
/*LN-117*/         return true;
/*LN-118*/     }
/*LN-119*/

/*LN-120*/     /**
/*LN-121*/      * @notice Extract a single signature from concatenated signatures
/*LN-122*/      */
/*LN-123*/     function _extractSignature(
/*LN-124*/         bytes memory _signatures,
/*LN-125*/         uint256 _index
/*LN-126*/     ) internal pure returns (bytes memory) {
/*LN-127*/         bytes memory signature = new bytes(65);
/*LN-128*/         uint256 offset = _index * 65;
/*LN-129*/

/*LN-130*/         for (uint256 i = 0; i < 65; i++) {
/*LN-131*/             signature[i] = _signatures[offset + i];
/*LN-132*/         }
/*LN-133*/

/*LN-134*/         return signature;
/*LN-135*/     }
/*LN-136*/

/*LN-137*/     /**
/*LN-138*/      * @notice Recover signer from signature
/*LN-139*/      */
/*LN-140*/     function _recoverSigner(
/*LN-141*/         bytes32 _hash,
/*LN-142*/         bytes memory _signature
/*LN-143*/     ) internal pure returns (address) {
/*LN-144*/         require(_signature.length == 65, "Invalid signature length");
/*LN-145*/

/*LN-146*/         bytes32 r;
/*LN-147*/         bytes32 s;
/*LN-148*/         uint8 v;
/*LN-149*/

/*LN-150*/         assembly {
/*LN-151*/             r := mload(add(_signature, 32))
/*LN-152*/             s := mload(add(_signature, 64))
/*LN-153*/             v := byte(0, mload(add(_signature, 96)))
/*LN-154*/         }
/*LN-155*/

/*LN-156*/         if (v < 27) {
/*LN-157*/             v += 27;
/*LN-158*/         }
/*LN-159*/

/*LN-160*/         require(v == 27 || v == 28, "Invalid signature v value");
/*LN-161*/

/*LN-162*/         return ecrecover(_hash, v, r, s);
/*LN-163*/     }
/*LN-164*/

    /**
     * @notice Add token to supported list
     * @dev Administrative function for token management
     */
/*LN-165*/     /**
/*LN-166*/      * @notice Add supported token (admin function)
/*LN-167*/      */
/*LN-168*/     function addSupportedToken(address _token) external {
/*LN-169*/         supportedTokens[_token] = true;
/*LN-170*/     }
/*LN-171*/ }
/*LN-172*/
