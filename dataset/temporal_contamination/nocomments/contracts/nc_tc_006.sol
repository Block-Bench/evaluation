/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract GameBridge {
/*LN-4*/ 
/*LN-5*/     address[] public validators;
/*LN-6*/     mapping(address => bool) public isValidator;
/*LN-7*/ 
/*LN-8*/     uint256 public requiredSignatures = 5;
/*LN-9*/     uint256 public validatorCount;
/*LN-10*/ 
/*LN-11*/ 
/*LN-12*/     mapping(uint256 => bool) public processedWithdrawals;
/*LN-13*/ 
/*LN-14*/ 
/*LN-15*/     mapping(address => bool) public supportedTokens;
/*LN-16*/ 
/*LN-17*/     event WithdrawalProcessed(
/*LN-18*/         uint256 indexed withdrawalId,
/*LN-19*/         address indexed user,
/*LN-20*/         address indexed token,
/*LN-21*/         uint256 amount
/*LN-22*/     );
/*LN-23*/ 
/*LN-24*/     constructor(address[] memory _validators) {
/*LN-25*/         require(
/*LN-26*/             _validators.length >= requiredSignatures,
/*LN-27*/             "Not enough validators"
/*LN-28*/         );
/*LN-29*/ 
/*LN-30*/         for (uint256 i = 0; i < _validators.length; i++) {
/*LN-31*/             address validator = _validators[i];
/*LN-32*/             require(validator != address(0), "Invalid validator");
/*LN-33*/             require(!isValidator[validator], "Duplicate validator");
/*LN-34*/ 
/*LN-35*/             validators.push(validator);
/*LN-36*/             isValidator[validator] = true;
/*LN-37*/         }
/*LN-38*/ 
/*LN-39*/         validatorCount = _validators.length;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function withdrawERC20For(
/*LN-43*/         uint256 _withdrawalId,
/*LN-44*/         address _user,
/*LN-45*/         address _token,
/*LN-46*/         uint256 _amount,
/*LN-47*/         bytes memory _signatures
/*LN-48*/     ) external {
/*LN-49*/ 
/*LN-50*/         require(!processedWithdrawals[_withdrawalId], "Already processed");
/*LN-51*/ 
/*LN-52*/ 
/*LN-53*/         require(supportedTokens[_token], "Token not supported");
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/         require(
/*LN-57*/             _verifySignatures(
/*LN-58*/                 _withdrawalId,
/*LN-59*/                 _user,
/*LN-60*/                 _token,
/*LN-61*/                 _amount,
/*LN-62*/                 _signatures
/*LN-63*/             ),
/*LN-64*/             "Invalid signatures"
/*LN-65*/         );
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/         processedWithdrawals[_withdrawalId] = true;
/*LN-69*/ 
/*LN-70*/ 
/*LN-71*/         emit WithdrawalProcessed(_withdrawalId, _user, _token, _amount);
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     function _verifySignatures(
/*LN-75*/         uint256 _withdrawalId,
/*LN-76*/         address _user,
/*LN-77*/         address _token,
/*LN-78*/         uint256 _amount,
/*LN-79*/         bytes memory _signatures
/*LN-80*/     ) internal view returns (bool) {
/*LN-81*/         require(_signatures.length % 65 == 0, "Invalid signature length");
/*LN-82*/ 
/*LN-83*/         uint256 signatureCount = _signatures.length / 65;
/*LN-84*/         require(signatureCount >= requiredSignatures, "Not enough signatures");
/*LN-85*/ 
/*LN-86*/ 
/*LN-87*/         bytes32 messageHash = keccak256(
/*LN-88*/             abi.encodePacked(_withdrawalId, _user, _token, _amount)
/*LN-89*/         );
/*LN-90*/         bytes32 ethSignedMessageHash = keccak256(
/*LN-91*/             abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
/*LN-92*/         );
/*LN-93*/ 
/*LN-94*/         address[] memory signers = new address[](signatureCount);
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/         for (uint256 i = 0; i < signatureCount; i++) {
/*LN-98*/             bytes memory signature = _extractSignature(_signatures, i);
/*LN-99*/             address signer = _recoverSigner(ethSignedMessageHash, signature);
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/             require(isValidator[signer], "Invalid signer");
/*LN-103*/ 
/*LN-104*/ 
/*LN-105*/             for (uint256 j = 0; j < i; j++) {
/*LN-106*/                 require(signers[j] != signer, "Duplicate signer");
/*LN-107*/             }
/*LN-108*/ 
/*LN-109*/             signers[i] = signer;
/*LN-110*/         }
/*LN-111*/ 
/*LN-112*/ 
/*LN-113*/         return true;
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/ 
/*LN-117*/     function _extractSignature(
/*LN-118*/         bytes memory _signatures,
/*LN-119*/         uint256 _index
/*LN-120*/     ) internal pure returns (bytes memory) {
/*LN-121*/         bytes memory signature = new bytes(65);
/*LN-122*/         uint256 offset = _index * 65;
/*LN-123*/ 
/*LN-124*/         for (uint256 i = 0; i < 65; i++) {
/*LN-125*/             signature[i] = _signatures[offset + i];
/*LN-126*/         }
/*LN-127*/ 
/*LN-128*/         return signature;
/*LN-129*/     }
/*LN-130*/ 
/*LN-131*/ 
/*LN-132*/     function _recoverSigner(
/*LN-133*/         bytes32 _hash,
/*LN-134*/         bytes memory _signature
/*LN-135*/     ) internal pure returns (address) {
/*LN-136*/         require(_signature.length == 65, "Invalid signature length");
/*LN-137*/ 
/*LN-138*/         bytes32 r;
/*LN-139*/         bytes32 s;
/*LN-140*/         uint8 v;
/*LN-141*/ 
/*LN-142*/         assembly {
/*LN-143*/             r := mload(add(_signature, 32))
/*LN-144*/             s := mload(add(_signature, 64))
/*LN-145*/             v := byte(0, mload(add(_signature, 96)))
/*LN-146*/         }
/*LN-147*/ 
/*LN-148*/         if (v < 27) {
/*LN-149*/             v += 27;
/*LN-150*/         }
/*LN-151*/ 
/*LN-152*/         require(v == 27 || v == 28, "Invalid signature v value");
/*LN-153*/ 
/*LN-154*/         return ecrecover(_hash, v, r, s);
/*LN-155*/     }
/*LN-156*/ 
/*LN-157*/ 
/*LN-158*/     function addSupportedToken(address _token) external {
/*LN-159*/         supportedTokens[_token] = true;
/*LN-160*/     }
/*LN-161*/ }