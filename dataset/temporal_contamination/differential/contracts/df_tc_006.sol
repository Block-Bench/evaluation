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
/*LN-23*/     event WithdrawalProcessed(
/*LN-24*/         uint256 indexed withdrawalId,
/*LN-25*/         address indexed user,
/*LN-26*/         address indexed token,
/*LN-27*/         uint256 amount
/*LN-28*/     );
/*LN-29*/ 
/*LN-30*/     constructor(address[] memory _validators) {
/*LN-31*/         require(
/*LN-32*/             _validators.length >= requiredSignatures,
/*LN-33*/             "Not enough validators"
/*LN-34*/         );
/*LN-35*/ 
/*LN-36*/         for (uint256 i = 0; i < _validators.length; i++) {
/*LN-37*/             address validator = _validators[i];
/*LN-38*/             require(validator != address(0), "Invalid validator");
/*LN-39*/             require(!isValidator[validator], "Duplicate validator");
/*LN-40*/ 
/*LN-41*/             validators.push(validator);
/*LN-42*/             isValidator[validator] = true;
/*LN-43*/         }
/*LN-44*/ 
/*LN-45*/         validatorCount = _validators.length;
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     /**
/*LN-49*/      * @notice Process a withdrawal request
/*LN-50*/      * @param _withdrawalId Unique ID for this withdrawal
/*LN-51*/      * @param _user Address to receive tokens
/*LN-52*/      * @param _token Token contract address
/*LN-53*/      * @param _amount Amount to withdraw
/*LN-54*/      * @param _signatures Concatenated validator signatures
/*LN-55*/      */
/*LN-56*/     function withdrawERC20For(
/*LN-57*/         uint256 _withdrawalId,
/*LN-58*/         address _user,
/*LN-59*/         address _token,
/*LN-60*/         uint256 _amount,
/*LN-61*/         bytes memory _signatures
/*LN-62*/     ) external {
/*LN-63*/         // Check if already processed
/*LN-64*/         require(!processedWithdrawals[_withdrawalId], "Already processed");
/*LN-65*/ 
/*LN-66*/         // Check if token is supported
/*LN-67*/         require(supportedTokens[_token], "Token not supported");
/*LN-68*/ 
/*LN-69*/         // Verify signatures
/*LN-70*/         require(
/*LN-71*/             _verifySignatures(
/*LN-72*/                 _withdrawalId,
/*LN-73*/                 _user,
/*LN-74*/                 _token,
/*LN-75*/                 _amount,
/*LN-76*/                 _signatures
/*LN-77*/             ),
/*LN-78*/             "Invalid signatures"
/*LN-79*/         );
/*LN-80*/ 
/*LN-81*/         // Mark as processed
/*LN-82*/         processedWithdrawals[_withdrawalId] = true;
/*LN-83*/ 
/*LN-84*/         // Transfer tokens
/*LN-85*/         emit WithdrawalProcessed(_withdrawalId, _user, _token, _amount);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     /**
/*LN-89*/      * @notice Verify validator signatures
/*LN-90*/      */
/*LN-91*/     function _verifySignatures(
/*LN-92*/         uint256 _withdrawalId,
/*LN-93*/         address _user,
/*LN-94*/         address _token,
/*LN-95*/         uint256 _amount,
/*LN-96*/         bytes memory _signatures
/*LN-97*/     ) internal view returns (bool) {
/*LN-98*/         require(_signatures.length % 65 == 0, "Invalid signature length");
/*LN-99*/ 
/*LN-100*/         uint256 signatureCount = _signatures.length / 65;
/*LN-101*/         require(signatureCount >= requiredSignatures, "Not enough signatures");
/*LN-102*/ 
/*LN-103*/         // Reconstruct the message hash
/*LN-104*/         bytes32 messageHash = keccak256(
/*LN-105*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-106*/         );
/*LN-107*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-108*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-109*/         );
/*LN-110*/ 
/*LN-111*/         address[] memory signers = new address[](signatureCount);
/*LN-112*/ 
/*LN-113*/         // Extract and verify each signature
/*LN-114*/         for (uint256 i = 0; i < signatureCount; i++) {
/*LN-115*/             bytes memory signature = _extractSignature(_signatures, i);
/*LN-116*/             address signer = _recoverSigner(ethSignedMessageHash, signature);
/*LN-117*/ 
/*LN-118*/             // Check if signer is a validator
/*LN-119*/             require(isValidator[signer], "Invalid signer");
/*LN-120*/ 
/*LN-121*/             // Check for duplicate signers
/*LN-122*/             for (uint256 j = 0; j < i; j++) {
/*LN-123*/                 require(signers[j] != signer, "Duplicate signer");
/*LN-124*/             }
/*LN-125*/ 
/*LN-126*/             signers[i] = signer;
/*LN-127*/         }
/*LN-128*/ 
/*LN-129*/         // All checks passed
/*LN-130*/         return true;
/*LN-131*/     }
/*LN-132*/ 
/*LN-133*/     /**
/*LN-134*/      * @notice Extract a single signature from concatenated signatures
/*LN-135*/      */
/*LN-136*/     function _extractSignature(
/*LN-137*/         bytes memory _signatures,
/*LN-138*/         uint256 _index
/*LN-139*/     ) internal pure returns (bytes memory) {
/*LN-140*/         bytes memory signature = new bytes(65);
/*LN-141*/         uint256 offset = _index * 65;
/*LN-142*/ 
/*LN-143*/         for (uint256 i = 0; i < 65; i++) {
/*LN-144*/             signature[i] = _signatures[offset + i];
/*LN-145*/         }
/*LN-146*/ 
/*LN-147*/         return signature;
/*LN-148*/     }
/*LN-149*/ 
/*LN-150*/     /**
/*LN-151*/      * @notice Recover signer from signature
/*LN-152*/      */
/*LN-153*/     function _recoverSigner(
/*LN-154*/         bytes32 _hash,
/*LN-155*/         bytes memory _signature
/*LN-156*/     ) internal pure returns (address) {
/*LN-157*/         require(_signature.length == 65, "Invalid signature length");
/*LN-158*/ 
/*LN-159*/         bytes32 r;
/*LN-160*/         bytes32 s;
/*LN-161*/         uint8 v;
/*LN-162*/ 
/*LN-163*/         assembly {
/*LN-164*/             r := mload(add(_signature, 32))
/*LN-165*/             s := mload(add(_signature, 64))
/*LN-166*/             v := byte(0, mload(add(_signature, 96)))
/*LN-167*/         }
/*LN-168*/ 
/*LN-169*/         if (v < 27) {
/*LN-170*/             v += 27;
/*LN-171*/         }
/*LN-172*/ 
/*LN-173*/         require(v == 27 || v == 28, "Invalid signature v value");
/*LN-174*/ 
/*LN-175*/         return ecrecover(_hash, v, r, s);
/*LN-176*/     }
/*LN-177*/ 
/*LN-178*/     /**
/*LN-179*/      * @notice Add supported token (admin function)
/*LN-180*/      */
/*LN-181*/     function addSupportedToken(address _token, bytes memory _signatures) external {
/*LN-182*/         require(!supportedTokens[_token], "Already supported");
/*LN-183*/         require(
/*LN-184*/             _verifySignatures(
/*LN-185*/                 uint256(uint160(_token)),
/*LN-186*/                 address(0),
/*LN-187*/                 _token,
/*LN-188*/                 0,
/*LN-189*/                 _signatures
/*LN-190*/             ),
/*LN-191*/             "Invalid signatures"
/*LN-192*/         );
/*LN-193*/         supportedTokens[_token] = true;
/*LN-194*/     }
/*LN-195*/ }
/*LN-196*/ 