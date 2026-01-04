/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * QUBIT BRIDGE EXPLOIT (January 2022)
/*LN-6*/  *
/*LN-7*/  * Attack Vector: Zero Address Validation Bypass
/*LN-8*/  * Loss: $80 million
/*LN-9*/  *
/*LN-10*/  * VULNERABILITY:
/*LN-11*/  * The Qubit Bridge allowed users to deposit tokens on Ethereum and mint
/*LN-12*/  * corresponding tokens on BSC. The vulnerability was in the deposit handler
/*LN-13*/  * which failed to validate that the deposited token address was not zero.
/*LN-14*/  *
/*LN-15*/  * By passing address(0) as the token contract, the attacker could bypass
/*LN-16*/  * the actual token transfer but still trigger minting on the destination chain.
/*LN-17*/  *
/*LN-18*/  * Attack Steps:
/*LN-19*/  * 1. Call deposit() with resourceID mapped to address(0)
/*LN-20*/  * 2. No tokens are actually transferred (address(0) has no code)
/*LN-21*/  * 3. Bridge emits deposit event anyway
/*LN-22*/  * 4. BSC handler sees event and mints tokens
/*LN-23*/  * 5. Attacker receives minted tokens without depositing real collateral
/*LN-24*/  * 6. Repeated calls to drain $80M from bridge reserves
/*LN-25*/  */
/*LN-26*/ 
/*LN-27*/ interface IERC20 {
/*LN-28*/     function transferFrom(
/*LN-29*/         address from,
/*LN-30*/         address to,
/*LN-31*/         uint256 amount
/*LN-32*/     ) external returns (bool);
/*LN-33*/ 
/*LN-34*/     function balanceOf(address account) external view returns (uint256);
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract QBridge {
/*LN-38*/     address public handler;
/*LN-39*/ 
/*LN-40*/     event Deposit(
/*LN-41*/         uint8 destinationDomainID,
/*LN-42*/         bytes32 resourceID,
/*LN-43*/         uint64 depositNonce
/*LN-44*/     );
/*LN-45*/ 
/*LN-46*/     uint64 public depositNonce;
/*LN-47*/ 
/*LN-48*/     constructor(address _handler) {
/*LN-49*/         handler = _handler;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     /**
/*LN-53*/      * @notice Initiates a bridge deposit
/*LN-54*/      * @dev VULNERABLE: Does not validate resourceID or token address
/*LN-55*/      */
/*LN-56*/     function deposit(
/*LN-57*/         uint8 destinationDomainID,
/*LN-58*/         bytes32 resourceID,
/*LN-59*/         bytes calldata data
/*LN-60*/     ) external payable {
/*LN-61*/         depositNonce += 1;
/*LN-62*/ 
/*LN-63*/         // Forward to handler - this is where the vulnerability occurs
/*LN-64*/         QBridgeHandler(handler).deposit(resourceID, msg.sender, data);
/*LN-65*/ 
/*LN-66*/         emit Deposit(destinationDomainID, resourceID, depositNonce);
/*LN-67*/     }
/*LN-68*/ }
/*LN-69*/ 
/*LN-70*/ contract QBridgeHandler {
/*LN-71*/     mapping(bytes32 => address) public resourceIDToTokenContractAddress;
/*LN-72*/     mapping(address => bool) public contractWhitelist;
/*LN-73*/ 
/*LN-74*/     /**
/*LN-75*/      * @notice Process bridge deposit
/*LN-76*/      * @dev VULNERABLE: Does not validate that tokenContract is not address(0)
/*LN-77*/      */
/*LN-78*/     function deposit(
/*LN-79*/         bytes32 resourceID,
/*LN-80*/         address depositer,
/*LN-81*/         bytes calldata data
/*LN-82*/     ) external {
/*LN-83*/         address tokenContract = resourceIDToTokenContractAddress[resourceID];
/*LN-84*/ 
/*LN-85*/         // VULNERABILITY: If tokenContract is address(0), this passes silently
/*LN-86*/         // contractWhitelist[address(0)] may be false, but the check might be skipped
/*LN-87*/         // or address(0) might accidentally be whitelisted
/*LN-88*/ 
/*LN-89*/         uint256 amount;
/*LN-90*/         (amount) = abi.decode(data, (uint256));
/*LN-91*/ 
/*LN-92*/         // CRITICAL VULNERABILITY: If tokenContract == address(0),
/*LN-93*/         // this call will not revert (calling address(0) returns success)
/*LN-94*/         // No tokens are actually transferred!
/*LN-95*/         IERC20(tokenContract).transferFrom(depositer, address(this), amount);
/*LN-96*/ 
/*LN-97*/         // But the deposit event was already emitted in the bridge contract
/*LN-98*/         // The destination chain handler sees this event and mints tokens
/*LN-99*/         // Attacker gets minted tokens without providing real collateral
/*LN-100*/     }
/*LN-101*/ 
/*LN-102*/     /**
/*LN-103*/      * @notice Set resource ID to token mapping
/*LN-104*/      */
/*LN-105*/     function setResource(bytes32 resourceID, address tokenAddress) external {
/*LN-106*/         resourceIDToTokenContractAddress[resourceID] = tokenAddress;
/*LN-107*/ 
/*LN-108*/         // VULNERABILITY: If tokenAddress is set to address(0), either accidentally
/*LN-109*/         // or through an attack, deposits with this resourceID will fail silently
/*LN-110*/         // but still emit events that trigger minting on destination chain
/*LN-111*/     }
/*LN-112*/ }
/*LN-113*/ 
/*LN-114*/ /**
/*LN-115*/  * EXPLOIT SCENARIO:
/*LN-116*/  *
/*LN-117*/  * Setup:
/*LN-118*/  * - Attacker finds or creates a resourceID that maps to address(0)
/*LN-119*/  * - This could happen if resourceID was never properly initialized
/*LN-120*/  * - Or if there's a way to manipulate the mapping
/*LN-121*/  *
/*LN-122*/  * Attack:
/*LN-123*/  * 1. Craft deposit() call with:
/*LN-124*/  *    - destinationDomainID: 1 (BSC)
/*LN-125*/  *    - resourceID: 0x0000...01 (maps to address(0))
/*LN-126*/  *    - data: encoded amount (e.g., 77,162 ETH worth)
/*LN-127*/  *
/*LN-128*/  * 2. Bridge calls handler.deposit(resourceID, attacker, data)
/*LN-129*/  *
/*LN-130*/  * 3. Handler retrieves tokenContract = address(0)
/*LN-131*/  *
/*LN-132*/  * 4. Handler calls IERC20(address(0)).transferFrom(...)
/*LN-133*/  *    - This does NOT revert (calling address(0) returns success in EVM)
/*LN-134*/  *    - No actual tokens are transferred
/*LN-135*/  *
/*LN-136*/  * 5. Bridge emits Deposit event
/*LN-137*/  *
/*LN-138*/  * 6. BSC side handler sees the event
/*LN-139*/  *
/*LN-140*/  * 7. BSC handler mints tokens to attacker's address
/*LN-141*/  *
/*LN-142*/  * 8. Attacker repeats multiple times to drain $80M
/*LN-143*/  *
/*LN-144*/  * Root Cause:
/*LN-145*/  * - Missing validation that tokenContract != address(0)
/*LN-146*/  * - Missing validation that resourceID is properly initialized
/*LN-147*/  * - Trusting that transferFrom to address(0) would revert
/*LN-148*/  *
/*LN-149*/  * Fix:
/*LN-150*/  * require(tokenContract != address(0), "Invalid token");
/*LN-151*/  * require(contractWhitelist[tokenContract], "Not whitelisted");
/*LN-152*/  */
/*LN-153*/ 