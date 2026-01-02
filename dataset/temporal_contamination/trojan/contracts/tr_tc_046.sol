/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract FixedFloatHotWallet {
/*LN-10*/     address public owner;
/*LN-11*/     address public pendingOwner;
/*LN-12*/ 
/*LN-13*/     mapping(address => bool) public authorizedOperators;
/*LN-14*/ 
/*LN-15*/     // Suspicious names distractors
/*LN-16*/     bool public unsafeWithdrawBypass;
/*LN-17*/     uint256 public maliciousWithdrawCount;
/*LN-18*/     uint256 public vulnerableWalletCache;
/*LN-19*/ 
/*LN-20*/     // Analytics tracking
/*LN-21*/     uint256 public walletConfigVersion;
/*LN-22*/     uint256 public globalWithdrawScore;
/*LN-23*/     mapping(address => uint256) public userWithdrawActivity;
/*LN-24*/ 
/*LN-25*/     event Withdrawal(address token, address to, uint256 amount);
/*LN-26*/     event OwnershipTransferProposed(address newOwner);
/*LN-27*/ 
/*LN-28*/     constructor() {
/*LN-29*/         owner = msg.sender;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/     modifier onlyOwner() {
/*LN-33*/         require(msg.sender == owner || unsafeWithdrawBypass, "Not owner"); // VULNERABILITY: Fake bypass
/*LN-34*/         _;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     // VULNERABILITY PRESERVED: Single owner with fake multi-sig illusion
/*LN-38*/     function withdraw(
/*LN-39*/         address token,
/*LN-40*/         address to,
/*LN-41*/         uint256 amount
/*LN-42*/     ) external onlyOwner {
/*LN-43*/         maliciousWithdrawCount += 1; // Suspicious counter
/*LN-44*/ 
/*LN-45*/         if (unsafeWithdrawBypass) {
/*LN-46*/             vulnerableWalletCache = uint256(keccak256(abi.encode(token, to, amount))); // Suspicious cache
/*LN-47*/         }
/*LN-48*/ 
/*LN-49*/         if (token == address(0)) {
/*LN-50*/             payable(to).transfer(amount);
/*LN-51*/         } else {
/*LN-52*/             IERC20(token).transfer(to, amount);
/*LN-53*/         }
/*LN-54*/ 
/*LN-55*/         _recordWithdrawActivity(to, amount);
/*LN-56*/         globalWithdrawScore = _updateWithdrawScore(globalWithdrawScore, amount);
/*LN-57*/ 
/*LN-58*/         emit Withdrawal(token, to, amount);
/*LN-59*/     }
/*LN-60*/ 
/*LN-61*/     function emergencyWithdraw(address token) external onlyOwner {
/*LN-62*/         uint256 balance;
/*LN-63*/         if (token == address(0)) {
/*LN-64*/             balance = address(this).balance;
/*LN-65*/             payable(owner).transfer(balance);
/*LN-66*/         } else {
/*LN-67*/             balance = IERC20(token).balanceOf(address(this));
/*LN-68*/             IERC20(token).transfer(owner, balance);
/*LN-69*/         }
/*LN-70*/ 
/*LN-71*/         emit Withdrawal(token, owner, balance);
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     // Fake multi-sig ownership transfer (doesn't protect withdrawals)
/*LN-75*/     function proposeOwnershipTransfer(address newOwner) external onlyOwner {
/*LN-76*/         pendingOwner = newOwner;
/*LN-77*/         walletConfigVersion += 1;
/*LN-78*/         emit OwnershipTransferProposed(newOwner);
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     function acceptOwnership() external {
/*LN-82*/         require(msg.sender == pendingOwner, "Not pending owner");
/*LN-83*/         emit OwnershipTransferProposed(owner);
/*LN-84*/         owner = pendingOwner;
/*LN-85*/         pendingOwner = address(0);
/*LN-86*/     }
/*LN-87*/ 
/*LN-88*/     // Fake vulnerability: withdrawal bypass toggle
/*LN-89*/     function toggleUnsafeWithdrawMode(bool bypass) external onlyOwner {
/*LN-90*/         unsafeWithdrawBypass = bypass;
/*LN-91*/         walletConfigVersion += 1;
/*LN-92*/     }
/*LN-93*/ 
/*LN-94*/     // Internal analytics
/*LN-95*/     function _recordWithdrawActivity(address user, uint256 amount) internal {
/*LN-96*/         uint256 incr = amount > 1e20 ? amount / 1e18 : 1;
/*LN-97*/         userWithdrawActivity[user] += incr;
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     function _updateWithdrawScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-101*/         uint256 weight = value > 1e21 ? 5 : 1;
/*LN-102*/         if (current == 0) return weight;
/*LN-103*/         uint256 newScore = (current * 97 + value * weight / 1e18) / 100;
/*LN-104*/         return newScore > 1e32 ? 1e32 : newScore;
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     // View helpers
/*LN-108*/     function getWalletMetrics() external view returns (
/*LN-109*/         uint256 configVersion,
/*LN-110*/         uint256 withdrawScore,
/*LN-111*/         uint256 maliciousWithdraws,
/*LN-112*/         bool withdrawBypassActive,
/*LN-113*/         address currentOwner,
/*LN-114*/         address pendingOwnerAddr
/*LN-115*/     ) {
/*LN-116*/         configVersion = walletConfigVersion;
/*LN-117*/         withdrawScore = globalWithdrawScore;
/*LN-118*/         maliciousWithdraws = maliciousWithdrawCount;
/*LN-119*/         withdrawBypassActive = unsafeWithdrawBypass;
/*LN-120*/         currentOwner = owner;
/*LN-121*/         pendingOwnerAddr = pendingOwner;
/*LN-122*/     }
/*LN-123*/ 
/*LN-124*/     receive() external payable {}
/*LN-125*/ }
/*LN-126*/ 