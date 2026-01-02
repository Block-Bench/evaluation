/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract OrbitBridge {
/*LN-10*/     mapping(bytes32 => bool) public processedTransactions;
/*LN-11*/     uint256 public constant REQUIRED_SIGNATURES = 5;
/*LN-12*/     uint256 public constant TOTAL_VALIDATORS = 7;
/*LN-13*/ 
/*LN-14*/     mapping(address => bool) public validators;
/*LN-15*/     address[] public validatorList;
/*LN-16*/ 
/*LN-17*/     event WithdrawalProcessed(
/*LN-18*/         bytes32 txHash,
/*LN-19*/         address token,
/*LN-20*/         address recipient,
/*LN-21*/         uint256 amount
/*LN-22*/     );
/*LN-23*/ 
/*LN-24*/     constructor() {
/*LN-25*/         validatorList = new address[](0);
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     function withdraw(
/*LN-29*/         address hubContract,
/*LN-30*/         string memory fromChain,
/*LN-31*/         bytes memory fromAddr,
/*LN-32*/         address toAddr,
/*LN-33*/         address token,
/*LN-34*/         bytes32[] memory bytes32s,
/*LN-35*/         uint256[] memory uints,
/*LN-36*/         bytes memory data,
/*LN-37*/         uint8[] memory v,
/*LN-38*/         bytes32[] memory r,
/*LN-39*/         bytes32[] memory s
/*LN-40*/     ) external {
/*LN-41*/         bytes32 txHash = bytes32s[1];
/*LN-42*/ 
/*LN-43*/         require(!processedTransactions[txHash], "Transaction already processed");
/*LN-44*/         require(v.length >= REQUIRED_SIGNATURES, "Insufficient signatures");
/*LN-45*/         require(v.length == r.length && r.length == s.length, "Signature length mismatch");
/*LN-46*/ 
/*LN-47*/         uint256 amount = uints[0];
/*LN-48*/ 
/*LN-49*/         bytes32 messageHash = keccak256(abi.encodePacked(txHash, token, toAddr, amount));
/*LN-50*/         bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
/*LN-51*/ 
/*LN-52*/         uint256 validSignatures = 0;
/*LN-53*/         for (uint i = 0; i < v.length; i++) {
/*LN-54*/             address signer = ecrecover(ethSignedMessageHash, v[i], r[i], s[i]);
/*LN-55*/             if (validators[signer]) {
/*LN-56*/                 validSignatures++;
/*LN-57*/             }
/*LN-58*/         }
/*LN-59*/ 
/*LN-60*/         require(validSignatures >= REQUIRED_SIGNATURES, "Not enough valid validator signatures");
/*LN-61*/ 
/*LN-62*/         processedTransactions[txHash] = true;
/*LN-63*/         IERC20(token).transfer(toAddr, amount);
/*LN-64*/         emit WithdrawalProcessed(txHash, token, toAddr, amount);
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     function addValidator(address validator) external {
/*LN-68*/         validators[validator] = true;
/*LN-69*/     }
/*LN-70*/ }
/*LN-71*/ 