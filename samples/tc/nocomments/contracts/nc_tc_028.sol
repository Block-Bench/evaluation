/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract CrossBridge {
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
/*LN-25*/ 
/*LN-26*/         validatorList = new address[](TOTAL_VALIDATORS);
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/ 
/*LN-30*/     function withdraw(
/*LN-31*/         address hubContract,
/*LN-32*/         string memory fromChain,
/*LN-33*/         bytes memory fromAddr,
/*LN-34*/         address toAddr,
/*LN-35*/         address token,
/*LN-36*/         bytes32[] memory bytes32s,
/*LN-37*/         uint256[] memory uints,
/*LN-38*/         bytes memory data,
/*LN-39*/         uint8[] memory v,
/*LN-40*/         bytes32[] memory r,
/*LN-41*/         bytes32[] memory s
/*LN-42*/     ) external {
/*LN-43*/         bytes32 txHash = bytes32s[1];
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         require(
/*LN-47*/             !processedTransactions[txHash],
/*LN-48*/             "Transaction already processed"
/*LN-49*/         );
/*LN-50*/ 
/*LN-51*/         require(v.length >= REQUIRED_SIGNATURES, "Insufficient signatures");
/*LN-52*/         require(
/*LN-53*/             v.length == r.length && r.length == s.length,
/*LN-54*/             "Signature length mismatch"
/*LN-55*/         );
/*LN-56*/ 
/*LN-57*/         uint256 amount = uints[0];
/*LN-58*/ 
/*LN-59*/ 
/*LN-60*/         processedTransactions[txHash] = true;
/*LN-61*/ 
/*LN-62*/ 
/*LN-63*/         IERC20(token).transfer(toAddr, amount);
/*LN-64*/ 
/*LN-65*/         emit WithdrawalProcessed(txHash, token, toAddr, amount);
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/     function addValidator(address validator) external {
/*LN-70*/         validators[validator] = true;
/*LN-71*/     }
/*LN-72*/ }