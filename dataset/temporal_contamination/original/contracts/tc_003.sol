/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Parity Multi-Sig Wallet Library (Vulnerable Version)
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the $150M+ Parity wallet freeze
/*LN-7*/  * @dev November 6, 2017 - Historic Ethereum vulnerability
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Unprotected initialization + delegatecall + selfdestruct
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * Parity used a library contract pattern where wallet proxies delegatecall to a shared
/*LN-13*/  * library contract (WalletLibrary). The library contract had an initialization function
/*LN-14*/  * initWallet() that was meant to be called via delegatecall from wallet proxies.
/*LN-15*/  *
/*LN-16*/  * However, the library contract itself could also be called directly (not via delegatecall),
/*LN-17*/  * and its initWallet() function was not protected. This meant anyone could:
/*LN-18*/  * 1. Call initWallet() directly on the library contract
/*LN-19*/  * 2. Become the owner of the library contract itself
/*LN-20*/  * 3. Call kill() to selfdestruct the library
/*LN-21*/  *
/*LN-22*/  * Once the library was destroyed, all wallet proxies that delegatecall to it became
/*LN-23*/  * permanently frozen, as they had no code to delegate to.
/*LN-24*/  *
/*LN-25*/  * ATTACK VECTOR:
/*LN-26*/  * 1. Attacker calls initWallet() directly on WalletLibrary contract
/*LN-27*/  * 2. Attacker becomes owner of the library (not intended behavior)
/*LN-28*/  * 3. Attacker calls kill() function
/*LN-29*/  * 4. Library contract self-destructs
/*LN-30*/  * 5. All 587 wallet proxies depending on this library are now frozen forever
/*LN-31*/  * 6. $150M+ in ETH and tokens permanently locked
/*LN-32*/  */
/*LN-33*/ 
/*LN-34*/ contract VulnerableParityWalletLibrary {
/*LN-35*/     // Owner mapping
/*LN-36*/     mapping(address => bool) public isOwner;
/*LN-37*/     address[] public owners;
/*LN-38*/     uint256 public required; // Number of signatures required
/*LN-39*/ 
/*LN-40*/     // Initialization state
/*LN-41*/     bool public initialized;
/*LN-42*/ 
/*LN-43*/     event OwnerAdded(address indexed owner);
/*LN-44*/     event WalletDestroyed(address indexed destroyer);
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Initialize the wallet with owners
/*LN-48*/      * @param _owners Array of owner addresses
/*LN-49*/      * @param _required Number of required signatures
/*LN-50*/      * @param _daylimit Daily withdrawal limit (unused in this example)
/*LN-51*/      *
/*LN-52*/      * CRITICAL VULNERABILITY:
/*LN-53*/      * This function lacks access control and can be called by anyone.
/*LN-54*/      * It was meant to be called via delegatecall from wallet proxies,
/*LN-55*/      * but it can also be called directly on the library contract.
/*LN-56*/      *
/*LN-57*/      * When called directly on the library (not via delegatecall),
/*LN-58*/      * the caller becomes the owner of the LIBRARY CONTRACT ITSELF,
/*LN-59*/      * not a wallet proxy. This allows them to destroy the library.
/*LN-60*/      */
/*LN-61*/     function initWallet(
/*LN-62*/         address[] memory _owners,
/*LN-63*/         uint256 _required,
/*LN-64*/         uint256 _daylimit
/*LN-65*/     ) public {
/*LN-66*/         // VULNERABILITY: No access control!
/*LN-67*/         // Should check: require(!initialized, "Already initialized");
/*LN-68*/         // But even that wouldn't fully protect the library contract
/*LN-69*/ 
/*LN-70*/         // In the real Parity wallet, this check existed but wasn't sufficient
/*LN-71*/         // because initialized state was in the proxy's storage, not library's storage
/*LN-72*/ 
/*LN-73*/         // Clear existing owners
/*LN-74*/         for (uint i = 0; i < owners.length; i++) {
/*LN-75*/             isOwner[owners[i]] = false;
/*LN-76*/         }
/*LN-77*/         delete owners;
/*LN-78*/ 
/*LN-79*/         // Set new owners
/*LN-80*/         for (uint i = 0; i < _owners.length; i++) {
/*LN-81*/             address owner = _owners[i];
/*LN-82*/             require(owner != address(0), "Invalid owner");
/*LN-83*/             require(!isOwner[owner], "Duplicate owner");
/*LN-84*/ 
/*LN-85*/             isOwner[owner] = true;
/*LN-86*/             owners.push(owner);
/*LN-87*/             emit OwnerAdded(owner);
/*LN-88*/         }
/*LN-89*/ 
/*LN-90*/         required = _required;
/*LN-91*/         initialized = true;
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     /**
/*LN-95*/      * @notice Check if an address is an owner
/*LN-96*/      * @param _addr Address to check
/*LN-97*/      * @return bool Whether the address is an owner
/*LN-98*/      */
/*LN-99*/     function isOwnerAddress(address _addr) public view returns (bool) {
/*LN-100*/         return isOwner[_addr];
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     /**
/*LN-104*/      * @notice Destroy the contract (selfdestruct)
/*LN-105*/      * @param _to Address to send remaining funds to
/*LN-106*/      *
/*LN-107*/      * CRITICAL VULNERABILITY:
/*LN-108*/      * This function allows owners to destroy the contract.
/*LN-109*/      * Combined with the initWallet vulnerability, an attacker can:
/*LN-110*/      * 1. Call initWallet() to become owner
/*LN-111*/      * 2. Call kill() to destroy the library
/*LN-112*/      * 3. Break all 587 wallet proxies that depend on this library
/*LN-113*/      *
/*LN-114*/      * The function only checks if caller is an owner, but doesn't prevent
/*LN-115*/      * the library contract itself from being destroyed.
/*LN-116*/      */
/*LN-117*/     function kill(address payable _to) external {
/*LN-118*/         require(isOwner[msg.sender], "Not an owner");
/*LN-119*/ 
/*LN-120*/         emit WalletDestroyed(msg.sender);
/*LN-121*/ 
/*LN-122*/         // VULNERABILITY: Destroys the library contract!
/*LN-123*/         // All wallet proxies delegatecalling to this library will break
/*LN-124*/         selfdestruct(_to);
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/     /**
/*LN-128*/      * @notice Example wallet function (simplified)
/*LN-129*/      * @dev All wallet proxies would delegatecall to functions like this
/*LN-130*/      */
/*LN-131*/     function execute(address to, uint256 value, bytes memory data) external {
/*LN-132*/         require(isOwner[msg.sender], "Not an owner");
/*LN-133*/ 
/*LN-134*/         (bool success, ) = to.call{value: value}(data);
/*LN-135*/         require(success, "Execution failed");
/*LN-136*/     }
/*LN-137*/ }
/*LN-138*/ 
/*LN-139*/ /**
/*LN-140*/  * Example Wallet Proxy (how real wallets used the library)
/*LN-141*/  */
/*LN-142*/ contract ParityWalletProxy {
/*LN-143*/     // Library address (where all the logic lives)
/*LN-144*/     address public libraryAddress;
/*LN-145*/ 
/*LN-146*/     constructor(address _library) {
/*LN-147*/         libraryAddress = _library;
/*LN-148*/     }
/*LN-149*/ 
/*LN-150*/     /**
/*LN-151*/      * Fallback function - delegates all calls to the library
/*LN-152*/      * When the library is destroyed via selfdestruct, this breaks completely
/*LN-153*/      */
/*LN-154*/     fallback() external payable {
/*LN-155*/         address lib = libraryAddress;
/*LN-156*/ 
/*LN-157*/         // Delegatecall to library
/*LN-158*/         assembly {
/*LN-159*/             calldatacopy(0, 0, calldatasize())
/*LN-160*/             let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
/*LN-161*/             returndatacopy(0, 0, returndatasize())
/*LN-162*/ 
/*LN-163*/             switch result
/*LN-164*/             case 0 {
/*LN-165*/                 revert(0, returndatasize())
/*LN-166*/             }
/*LN-167*/             default {
/*LN-168*/                 return(0, returndatasize())
/*LN-169*/             }
/*LN-170*/         }
/*LN-171*/     }
/*LN-172*/ 
/*LN-173*/     receive() external payable {}
/*LN-174*/ }
/*LN-175*/ 
/*LN-176*/ /**
/*LN-177*/  * REAL-WORLD IMPACT:
/*LN-178*/  * - $150M+ frozen permanently (not stolen, but locked forever)
/*LN-179*/  * - 587 wallet contracts affected
/*LN-180*/  * - Wallets included major organizations and ICO funds
/*LN-181*/  * - Some of the most prominent Ethereum projects lost access to treasuries
/*LN-182*/  * - Funds remain frozen to this day (cannot be recovered)
/*LN-183*/  *
/*LN-184*/  * FIX:
/*LN-185*/  * The fix required:
/*LN-186*/  * 1. Library contracts should not have initialization functions that can be called directly
/*LN-187*/  * 2. Library contracts should not have selfdestruct functions
/*LN-188*/  * 3. If using proxy pattern, clearly separate proxy storage from library logic
/*LN-189*/  * 4. Library contracts should use Solidity's 'library' keyword (not 'contract')
/*LN-190*/  * 5. Add access controls to ensure library cannot be initialized after deployment
/*LN-191*/  * 6. Consider using upgradeable proxy patterns (EIP-1967, etc.) with proper guards
/*LN-192*/  *
/*LN-193*/  * KEY LESSON:
/*LN-194*/  * The delegatecall proxy pattern is dangerous if not implemented correctly.
/*LN-195*/  * Library contracts should NEVER have state-changing functions that can be
/*LN-196*/  * called directly. The combination of unprotected initialization + selfdestruct
/*LN-197*/  * in a library contract was catastrophic.
/*LN-198*/  *
/*LN-199*/  * This bug was discovered by a user who accidentally triggered it, not by
/*LN-200*/  * a malicious attacker. They called initWallet() and kill() thinking they
/*LN-201*/  * were testing their own wallet, but actually destroyed the shared library.
/*LN-202*/  *
/*LN-203*/  */
/*LN-204*/ 