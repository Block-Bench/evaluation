/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Poly Network Cross-Chain Manager (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $611M Poly Network hack
/*LN-7*/  * @dev August 10, 2021 - One of the largest crypto hacks ever
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Unrestricted target contract in cross-chain execution
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * Poly Network's EthCrossChainManager allowed anyone to execute cross-chain
/*LN-13*/  * transactions by providing:
/*LN-14*/  * 1. A valid block header from the source chain (with signatures)
/*LN-15*/  * 2. A merkle proof showing the transaction was in that block
/*LN-16*/  *
/*LN-17*/  * The vulnerability: The contract validated the header and proof, but didn't
/*LN-18*/  * restrict WHICH contract could be called as the target. Attackers could:
/*LN-19*/  * 1. Create a valid cross-chain message on the source chain
/*LN-20*/  * 2. Set the target to EthCrossChainData (the privileged data contract)
/*LN-21*/  * 3. Call functions on EthCrossChainData that should be onlyOwner
/*LN-22*/  * 4. The onlyOwner check would pass because msg.sender was EthCrossChainManager!
/*LN-23*/  *
/*LN-24*/  * ATTACK VECTOR:
/*LN-25*/  * 1. Attacker crafts cross-chain transaction on Poly Network sidechain
/*LN-26*/  * 2. Transaction targets EthCrossChainData contract (not checked!)
/*LN-27*/  * 3. Transaction calls putCurEpochConPubKeyBytes() to change validator keys
/*LN-28*/  * 4. EthCrossChainManager verifies the transaction (valid!)
/*LN-29*/  * 5. EthCrossChainManager calls EthCrossChainData.putCurEpochConPubKeyBytes()
/*LN-30*/  * 6. onlyOwner check passes (msg.sender == EthCrossChainManager)
/*LN-31*/  * 7. Attacker's public keys are set as new validators
/*LN-32*/  * 8. Attacker can now forge any cross-chain transaction
/*LN-33*/  * 9. Drain all assets from bridge
/*LN-34*/  */
/*LN-35*/ 
/*LN-36*/ interface IEthCrossChainData {
/*LN-37*/     function transferOwnership(address newOwner) external;
/*LN-38*/ 
/*LN-39*/     function putCurEpochConPubKeyBytes(
/*LN-40*/         bytes calldata curEpochPkBytes
/*LN-41*/     ) external returns (bool);
/*LN-42*/ 
/*LN-43*/     function getCurEpochConPubKeyBytes() external view returns (bytes memory);
/*LN-44*/ }
/*LN-45*/ 
/*LN-46*/ contract EthCrossChainData {
/*LN-47*/     address public owner;
/*LN-48*/     bytes public currentEpochPublicKeys; // Validator public keys
/*LN-49*/ 
/*LN-50*/     event OwnershipTransferred(
/*LN-51*/         address indexed previousOwner,
/*LN-52*/         address indexed newOwner
/*LN-53*/     );
/*LN-54*/     event PublicKeysUpdated(bytes newKeys);
/*LN-55*/ 
/*LN-56*/     constructor() {
/*LN-57*/         owner = msg.sender;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     modifier onlyOwner() {
/*LN-61*/         require(msg.sender == owner, "Not owner");
/*LN-62*/         _;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     /**
/*LN-66*/      * @notice Update validator public keys
/*LN-67*/      * @dev VULNERABILITY: Can be called by EthCrossChainManager via cross-chain tx
/*LN-68*/      */
/*LN-69*/     function putCurEpochConPubKeyBytes(
/*LN-70*/         bytes calldata curEpochPkBytes
/*LN-71*/     ) external onlyOwner returns (bool) {
/*LN-72*/         currentEpochPublicKeys = curEpochPkBytes;
/*LN-73*/         emit PublicKeysUpdated(curEpochPkBytes);
/*LN-74*/         return true;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     /**
/*LN-78*/      * @notice Transfer ownership
/*LN-79*/      * @dev VULNERABILITY: Can be called by EthCrossChainManager via cross-chain tx
/*LN-80*/      */
/*LN-81*/     function transferOwnership(address newOwner) external onlyOwner {
/*LN-82*/         require(newOwner != address(0), "Invalid address");
/*LN-83*/         emit OwnershipTransferred(owner, newOwner);
/*LN-84*/         owner = newOwner;
/*LN-85*/     }
/*LN-86*/ 
/*LN-87*/     function getCurEpochConPubKeyBytes() external view returns (bytes memory) {
/*LN-88*/         return currentEpochPublicKeys;
/*LN-89*/     }
/*LN-90*/ }
/*LN-91*/ 
/*LN-92*/ contract VulnerableEthCrossChainManager {
/*LN-93*/     address public dataContract; // EthCrossChainData address
/*LN-94*/ 
/*LN-95*/     event CrossChainEvent(
/*LN-96*/         address indexed fromContract,
/*LN-97*/         bytes toContract,
/*LN-98*/         bytes method
/*LN-99*/     );
/*LN-100*/ 
/*LN-101*/     constructor(address _dataContract) {
/*LN-102*/         dataContract = _dataContract;
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     /**
/*LN-106*/      * @notice Verify and execute cross-chain transaction
/*LN-107*/      * @param proof Merkle proof of transaction inclusion
/*LN-108*/      * @param rawHeader Block header from source chain
/*LN-109*/      * @param headerProof Proof of header validity
/*LN-110*/      * @param curRawHeader Current header
/*LN-111*/      * @param headerSig Validator signatures
/*LN-112*/      *
/*LN-113*/      * CRITICAL VULNERABILITY:
/*LN-114*/      * This function verifies that a transaction happened on the source chain,
/*LN-115*/      * then executes it. However, it doesn't restrict the TARGET of execution.
/*LN-116*/      *
/*LN-117*/      * The attacker can target dataContract (EthCrossChainData) and call
/*LN-118*/      * privileged functions. Since msg.sender will be this contract,
/*LN-119*/      * the onlyOwner check in EthCrossChainData will pass!
/*LN-120*/      */
/*LN-121*/     function verifyHeaderAndExecuteTx(
/*LN-122*/         bytes memory proof,
/*LN-123*/         bytes memory rawHeader,
/*LN-124*/         bytes memory headerProof,
/*LN-125*/         bytes memory curRawHeader,
/*LN-126*/         bytes memory headerSig
/*LN-127*/     ) external returns (bool) {
/*LN-128*/         // Step 1: Verify the block header is valid (signatures from validators)
/*LN-129*/         // Simplified - in reality, this checks validator signatures
/*LN-130*/         require(_verifyHeader(rawHeader, headerSig), "Invalid header");
/*LN-131*/ 
/*LN-132*/         // Step 2: Verify the transaction was included in that block (Merkle proof)
/*LN-133*/         // Simplified - in reality, this verifies Merkle proof
/*LN-134*/         require(_verifyProof(proof, rawHeader), "Invalid proof");
/*LN-135*/ 
/*LN-136*/         // Step 3: Decode the transaction data
/*LN-137*/         (
/*LN-138*/             address toContract,
/*LN-139*/             bytes memory method,
/*LN-140*/             bytes memory args
/*LN-141*/         ) = _decodeTx(proof);
/*LN-142*/ 
/*LN-143*/         // VULNERABILITY: No check on toContract!
/*LN-144*/         // Attacker can set toContract = dataContract
/*LN-145*/         // This allows calling privileged functions on EthCrossChainData
/*LN-146*/ 
/*LN-147*/         // Execute the transaction
/*LN-148*/         // VULNERABILITY: When calling dataContract, msg.sender is THIS CONTRACT
/*LN-149*/         // So onlyOwner checks in EthCrossChainData will pass!
/*LN-150*/         (bool success, ) = toContract.call(abi.encodePacked(method, args));
/*LN-151*/         require(success, "Execution failed");
/*LN-152*/ 
/*LN-153*/         return true;
/*LN-154*/     }
/*LN-155*/ 
/*LN-156*/     /**
/*LN-157*/      * @notice Verify block header signatures (simplified)
/*LN-158*/      */
/*LN-159*/     function _verifyHeader(
/*LN-160*/         bytes memory rawHeader,
/*LN-161*/         bytes memory headerSig
/*LN-162*/     ) internal pure returns (bool) {
/*LN-163*/         // Simplified: In reality, this verifies validator signatures
/*LN-164*/         // The attacker provided VALID headers and signatures
/*LN-165*/         return true;
/*LN-166*/     }
/*LN-167*/ 
/*LN-168*/     /**
/*LN-169*/      * @notice Verify Merkle proof (simplified)
/*LN-170*/      */
/*LN-171*/     function _verifyProof(
/*LN-172*/         bytes memory proof,
/*LN-173*/         bytes memory rawHeader
/*LN-174*/     ) internal pure returns (bool) {
/*LN-175*/         // Simplified: In reality, this verifies Merkle proof
/*LN-176*/         // The attacker provided VALID proofs
/*LN-177*/         return true;
/*LN-178*/     }
/*LN-179*/ 
/*LN-180*/     /**
/*LN-181*/      * @notice Decode transaction data (simplified)
/*LN-182*/      */
/*LN-183*/     function _decodeTx(
/*LN-184*/         bytes memory proof
/*LN-185*/     )
/*LN-186*/         internal
/*LN-187*/         view
/*LN-188*/         returns (address toContract, bytes memory method, bytes memory args)
/*LN-189*/     {
/*LN-190*/         // Simplified decoding
/*LN-191*/         // In the real attack:
/*LN-192*/         // toContract = dataContract (EthCrossChainData address)
/*LN-193*/         // method = "putCurEpochConPubKeyBytes" function selector
/*LN-194*/         // args = attacker's public keys
/*LN-195*/ 
/*LN-196*/         toContract = dataContract; // VULNERABILITY: Attacker chose this!
/*LN-197*/         method = abi.encodeWithSignature(
/*LN-198*/             "putCurEpochConPubKeyBytes(bytes)",
/*LN-199*/             ""
/*LN-200*/         );
/*LN-201*/         args = ""; // Would contain attacker's keys
/*LN-202*/     }
/*LN-203*/ }
/*LN-204*/ 
/*LN-205*/ /**
/*LN-206*/  * REAL-WORLD IMPACT:
/*LN-207*/  * - $611M stolen on August 10, 2021
/*LN-208*/  * - One of the largest crypto hacks ever
/*LN-209*/  * - Affected assets on Ethereum, BSC, and Polygon
/*LN-210*/  * - Most funds were later returned by the attacker (white hat behavior?)
/*LN-211*/  *
/*LN-212*/  * ATTACK FLOW:
/*LN-213*/  * 1. Attacker creates transaction on Poly Network sidechain
/*LN-214*/  * 2. Transaction targets EthCrossChainData contract (not a user contract!)
/*LN-215*/  * 3. Transaction calls putCurEpochConPubKeyBytes() with attacker's keys
/*LN-216*/  * 4. Attacker calls verifyHeaderAndExecuteTx() with valid proof
/*LN-217*/  * 5. EthCrossChainManager verifies: header ✓, proof ✓, execute!
/*LN-218*/  * 6. Calls EthCrossChainData.putCurEpochConPubKeyBytes()
/*LN-219*/  * 7. msg.sender is EthCrossChainManager, onlyOwner check passes ✓
/*LN-220*/  * 8. Attacker's keys become validator keys
/*LN-221*/  * 9. Attacker can now forge transactions to drain bridge
/*LN-222*/  *
/*LN-223*/  * FIX:
/*LN-224*/  * The fix required:
/*LN-225*/  * 1. Whitelist of allowed target contracts (exclude dataContract!)
/*LN-226*/  * 2. Blacklist of forbidden targets (include dataContract)
/*LN-227*/  * 3. Separate privilege levels for cross-chain execution
/*LN-228*/  * 4. Use a different authorization mechanism (not msg.sender based)
/*LN-229*/  * 5. Implement more granular access controls
/*LN-230*/  * 6. Add emergency pause mechanisms
/*LN-231*/  * 7. Multi-sig for critical operations like key updates
/*LN-232*/  *
/*LN-233*/  * KEY LESSON:
/*LN-234*/  * When building proxy/manager contracts that execute arbitrary calls,
/*LN-235*/  * always restrict the TARGET of those calls. Don't allow calling privileged
/*LN-236*/  * contracts that trust the manager.
/*LN-237*/  *
/*LN-238*/  * The vulnerability was a classic access control bypass:
/*LN-239*/  * - EthCrossChainData trusted EthCrossChainManager (onlyOwner)
/*LN-240*/  * - EthCrossChainManager allowed calling ANY contract
/*LN-241*/  * - Result: Anyone could call privileged functions via the manager
/*LN-242*/  *
/*LN-243*/  *
/*LN-244*/  * NOTE ON AFTERMATH:
/*LN-245*/  * Interestingly, the attacker returned most of the stolen funds, leading
/*LN-246*/  * to speculation they were a white hat hacker demonstrating the vulnerability.
/*LN-247*/  * They communicated via embedded messages in transactions, stating they did
/*LN-248*/  * it "for fun" and were "ready to return the funds."
/*LN-249*/  */
/*LN-250*/ 