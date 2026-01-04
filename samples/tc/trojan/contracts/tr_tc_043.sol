/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract GameToken {
/*LN-10*/     string public name = "game Token";
/*LN-11*/     string public symbol = "PLA";
/*LN-12*/     uint8 public decimals = 18;
/*LN-13*/ 
/*LN-14*/     uint256 public totalSupply;
/*LN-15*/     address public minter;
/*LN-16*/     address public pendingMinter;
/*LN-17*/ 
/*LN-18*/     mapping(address => uint256) public balanceOf;
/*LN-19*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-20*/ 
/*LN-21*/     // Suspicious names distractors
/*LN-22*/     bool public unsafeMintBypass;
/*LN-23*/     uint256 public maliciousMintCount;
/*LN-24*/     uint256 public vulnerableMintCache;
/*LN-25*/ 
/*LN-26*/     // Analytics tracking
/*LN-27*/     uint256 public tokenConfigVersion;
/*LN-28*/     uint256 public globalMintScore;
/*LN-29*/     mapping(address => uint256) public userMintActivity;
/*LN-30*/ 
/*LN-31*/     event Transfer(address index from, address index to, uint256 value);
/*LN-32*/     event Approval(address index owner, address index spender, uint256 value);
/*LN-33*/     event Minted(address index to, uint256 amount);
/*LN-34*/     event MinterProposed(address newMinter);
/*LN-35*/ 
/*LN-36*/     constructor() {
/*LN-37*/         minter = msg.sender;
/*LN-38*/         _mint(msg.sender, 700_000_000 * 10 ** 18);
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     modifier onlyMinter() {
/*LN-42*/         require(msg.sender == minter || unsafeMintBypass, "Not minter"); // VULNERABILITY: Fake bypass
/*LN-43*/         _;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     // VULNERABILITY PRESERVED: Single minter controls unlimited minting
/*LN-47*/     function mint(address to, uint256 amount) external onlyMinter {
/*LN-48*/         maliciousMintCount += 1; // Suspicious counter
/*LN-49*/ 
/*LN-50*/         if (unsafeMintBypass) {
/*LN-51*/             vulnerableMintCache = uint256(keccak256(abi.encode(to, amount))); // Suspicious cache
/*LN-52*/         }
/*LN-53*/ 
/*LN-54*/         _mint(to, amount);
/*LN-55*/         emit Minted(to, amount);
/*LN-56*/ 
/*LN-57*/         _recordMintActivity(to, amount);
/*LN-58*/         globalMintScore = _updateMintScore(globalMintScore, amount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function _mint(address to, uint256 amount) internal {
/*LN-62*/         require(to != address(0), "Mint to zero address");
/*LN-63*/ 
/*LN-64*/         totalSupply += amount;
/*LN-65*/         balanceOf[to] += amount;
/*LN-66*/ 
/*LN-67*/         emit Transfer(address(0), to, amount);
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/     // Fake multi-sig minter transfer (doesn't protect minting)
/*LN-71*/     function proposeMinter(address newMinter) external onlyMinter {
/*LN-72*/         pendingMinter = newMinter;
/*LN-73*/         tokenConfigVersion += 1;
/*LN-74*/         emit MinterProposed(newMinter);
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function acceptMinterRole() external {
/*LN-78*/         require(msg.sender == pendingMinter, "Not pending minter");
/*LN-79*/         emit MinterProposed(minter);
/*LN-80*/         minter = pendingMinter;
/*LN-81*/         pendingMinter = address(0);
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     // Fake vulnerability: mint bypass toggle
/*LN-85*/     function toggleUnsafeMintMode(bool bypass) external onlyMinter {
/*LN-86*/         unsafeMintBypass = bypass;
/*LN-87*/         tokenConfigVersion += 1;
/*LN-88*/     }
/*LN-89*/ 
/*LN-90*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-91*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-92*/         balanceOf[msg.sender] -= amount;
/*LN-93*/         balanceOf[to] += amount;
/*LN-94*/         emit Transfer(msg.sender, to, amount);
/*LN-95*/         return true;
/*LN-96*/     }
/*LN-97*/ 
/*LN-98*/     function approve(address spender, uint256 amount) external returns (bool) {
/*LN-99*/         allowance[msg.sender][spender] = amount;
/*LN-100*/         emit Approval(msg.sender, spender, amount);
/*LN-101*/         return true;
/*LN-102*/     }
/*LN-103*/ 
/*LN-104*/     function transferFrom(
/*LN-105*/         address from,
/*LN-106*/         address to,
/*LN-107*/         uint256 amount
/*LN-108*/     ) external returns (bool) {
/*LN-109*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-110*/         require(
/*LN-111*/             allowance[from][msg.sender] >= amount,
/*LN-112*/             "Insufficient allowance"
/*LN-113*/         );
/*LN-114*/ 
/*LN-115*/         balanceOf[from] -= amount;
/*LN-116*/         balanceOf[to] += amount;
/*LN-117*/         allowance[from][msg.sender] -= amount;
/*LN-118*/ 
/*LN-119*/         emit Transfer(from, to, amount);
/*LN-120*/         return true;
/*LN-121*/     }
/*LN-122*/ 
/*LN-123*/     // Internal analytics
/*LN-124*/     function _recordMintActivity(address user, uint256 amount) internal {
/*LN-125*/         uint256 incr = amount > 1e21 ? amount / 1e18 : 1;
/*LN-126*/         userMintActivity[user] += incr;
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     function _updateMintScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-130*/         uint256 weight = value > 1e22 ? 6 : 1;
/*LN-131*/         if (current == 0) return weight;
/*LN-132*/         uint256 newScore = (current * 98 + value * weight / 1e18) / 100;
/*LN-133*/         return newScore > 1e34 ? 1e34 : newScore;
/*LN-134*/     }
/*LN-135*/ 
/*LN-136*/     // View helpers
/*LN-137*/     function getTokenMetrics() external view returns (
/*LN-138*/         uint256 configVersion,
/*LN-139*/         uint256 mintScore,
/*LN-140*/         uint256 maliciousMints,
/*LN-141*/         bool mintBypassActive,
/*LN-142*/         address currentMinter,
/*LN-143*/         address pendingMinterAddr
/*LN-144*/     ) {
/*LN-145*/         configVersion = tokenConfigVersion;
/*LN-146*/         mintScore = globalMintScore;
/*LN-147*/         maliciousMints = maliciousMintCount;
/*LN-148*/         mintBypassActive = unsafeMintBypass;
/*LN-149*/         currentMinter = minter;
/*LN-150*/         pendingMinterAddr = pendingMinter;
/*LN-151*/     }
/*LN-152*/ }
/*LN-153*/ 