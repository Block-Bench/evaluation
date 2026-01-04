/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * SENECA PROTOCOL EXPLOIT (February 2024)
/*LN-6*/  * Loss: $6.4 million
/*LN-7*/  * Attack: Arbitrary Call via performOperations Function
/*LN-8*/  *
/*LN-9*/  * Seneca Protocol (Chamber) allowed users to execute operations on their vaults.
/*LN-10*/  * The performOperations function accepted user-controlled target addresses and
/*LN-11*/  * calldata, enabling attackers to call transferFrom on any token where users
/*LN-12*/  * had given approvals to the Chamber contract.
/*LN-13*/  */
/*LN-14*/ 
/*LN-15*/ interface IERC20 {
/*LN-16*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-17*/ 
/*LN-18*/     function transferFrom(
/*LN-19*/         address from,
/*LN-20*/         address to,
/*LN-21*/         uint256 amount
/*LN-22*/     ) external returns (bool);
/*LN-23*/ 
/*LN-24*/     function balanceOf(address account) external view returns (uint256);
/*LN-25*/ 
/*LN-26*/     function approve(address spender, uint256 amount) external returns (bool);
/*LN-27*/ }
/*LN-28*/ 
/*LN-29*/ contract SenecaChamber {
/*LN-30*/     uint8 public constant OPERATION_CALL = 30;
/*LN-31*/     uint8 public constant OPERATION_DELEGATECALL = 31;
/*LN-32*/ 
/*LN-33*/     mapping(address => bool) public vaultOwners;
/*LN-34*/ 
/*LN-35*/     /**
/*LN-36*/      * @notice Execute multiple operations on the vault
/*LN-37*/      * @dev VULNERABILITY: Accepts arbitrary addresses and calldata
/*LN-38*/      */
/*LN-39*/     function performOperations(
/*LN-40*/         uint8[] memory actions,
/*LN-41*/         uint256[] memory values,
/*LN-42*/         bytes[] memory datas
/*LN-43*/     ) external payable returns (uint256 value1, uint256 value2) {
/*LN-44*/         require(
/*LN-45*/             actions.length == values.length && values.length == datas.length,
/*LN-46*/             "Length mismatch"
/*LN-47*/         );
/*LN-48*/ 
/*LN-49*/         for (uint256 i = 0; i < actions.length; i++) {
/*LN-50*/             if (actions[i] == OPERATION_CALL) {
/*LN-51*/                 // VULNERABILITY 1: User-controlled target address and calldata
/*LN-52*/                 // Decode target from user-provided data
/*LN-53*/                 (address target, bytes memory callData, , , ) = abi.decode(
/*LN-54*/                     datas[i],
/*LN-55*/                     (address, bytes, uint256, uint256, uint256)
/*LN-56*/                 );
/*LN-57*/ 
/*LN-58*/                 // VULNERABILITY 2: No whitelist of allowed target contracts
/*LN-59*/                 // Can call any address including token contracts
/*LN-60*/ 
/*LN-61*/                 // VULNERABILITY 3: No validation of callData contents
/*LN-62*/                 // Attacker can encode transferFrom() calls
/*LN-63*/ 
/*LN-64*/                 // VULNERABILITY 4: Arbitrary external call
/*LN-65*/                 // msg.sender becomes Chamber contract which has user approvals
/*LN-66*/                 (bool success, ) = target.call{value: values[i]}(callData);
/*LN-67*/                 require(success, "Call failed");
/*LN-68*/             }
/*LN-69*/         }
/*LN-70*/ 
/*LN-71*/         return (0, 0);
/*LN-72*/     }
/*LN-73*/ }
/*LN-74*/ 
/*LN-75*/ /**
/*LN-76*/  * EXPLOIT SCENARIO:
/*LN-77*/  *
/*LN-78*/  * 1. Attacker identifies victim with token approval:
/*LN-79*/  *    - Victim: 0x9CBF099ff424979439dFBa03F00B5961784c06ce
/*LN-80*/  *    - Has approved Chamber contract for Pendle Principal Tokens
/*LN-81*/  *    - Token balance: Large amount of valuable tokens
/*LN-82*/  *
/*LN-83*/  * 2. Attacker crafts malicious operation data:
/*LN-84*/  *    - Action: OPERATION_CALL (30)
/*LN-85*/  *    - Target: PendlePrincipalToken contract address
/*LN-86*/  *    - CallData: transferFrom(victim, attacker, victimBalance)
/*LN-87*/  *    - Encode as: abi.encode(tokenAddress, callData, 0, 0, 0)
/*LN-88*/  *
/*LN-89*/  * 3. Attacker calls performOperations():
/*LN-90*/  *    ```solidity
/*LN-91*/  *    uint8[] memory actions = [OPERATION_CALL];
/*LN-92*/  *    uint256[] memory values = [0];
/*LN-93*/  *    bytes memory callData = abi.encodeWithSignature(
/*LN-94*/  *        "transferFrom(address,address,uint256)",
/*LN-95*/  *        victim,
/*LN-96*/  *        attacker,
/*LN-97*/  *        victimBalance
/*LN-98*/  *    );
/*LN-99*/  *    bytes memory data = abi.encode(tokenAddress, callData, 0, 0, 0);
/*LN-100*/  *    bytes[] memory datas = [data];
/*LN-101*/  *
/*LN-102*/  *    chamber.performOperations(actions, values, datas);
/*LN-103*/  *    ```
/*LN-104*/  *
/*LN-105*/  * 4. Chamber executes the malicious call:
/*LN-106*/  *    - Decodes target (token contract) and callData from datas
/*LN-107*/  *    - Makes external call: token.call(callData)
/*LN-108*/  *    - msg.sender is Chamber contract
/*LN-109*/  *
/*LN-110*/  * 5. Token contract processes transferFrom:
/*LN-111*/  *    - Checks if Chamber (msg.sender) has approval from victim
/*LN-112*/  *    - Approval exists because victim approved Chamber
/*LN-113*/  *    - Transfers tokens from victim to attacker
/*LN-114*/  *
/*LN-115*/  * 6. Attacker receives stolen tokens:
/*LN-116*/  *    - Gets victim's entire token balance
/*LN-117*/  *    - Repeat for multiple victims
/*LN-118*/  *    - Total stolen: $6.4M
/*LN-119*/  *
/*LN-120*/  * Root Causes:
/*LN-121*/  * - User-controlled target address in performOperations
/*LN-122*/  * - User-controlled calldata without validation
/*LN-123*/  * - No whitelist of approved target contracts
/*LN-124*/  * - Arbitrary external calls allowed
/*LN-125*/  * - Users gave unlimited approvals to Chamber
/*LN-126*/  * - No function selector validation
/*LN-127*/  * - Missing access controls on operation types
/*LN-128*/  * - No validation that operations benefit vault owner
/*LN-129*/  *
/*LN-130*/  * Fix:
/*LN-131*/  * - Whitelist allowed target contract addresses
/*LN-132*/  * - Whitelist allowed function selectors
/*LN-133*/  * - Never allow transferFrom calls on arbitrary tokens
/*LN-134*/  * - Validate operations only affect caller's own assets
/*LN-135*/  * - Implement approval scoping (Permit2 pattern)
/*LN-136*/  * - Add operation type restrictions per user role
/*LN-137*/  * - Require explicit confirmation for token transfers
/*LN-138*/  * - Monitor for suspicious operation patterns
/*LN-139*/  * - Implement pause mechanism
/*LN-140*/  * - Add maximum transfer amounts per operation
/*LN-141*/  */
/*LN-142*/ 