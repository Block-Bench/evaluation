/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract FixedFloatHotWallet {
/*LN-11*/     address public owner;
/*LN-12*/ 
/*LN-13*/     mapping(address => bool) public authorizedOperators;
/*LN-14*/ 
/*LN-15*/     // Timelock for large withdrawals
/*LN-16*/     uint256 public constant TIMELOCK_DELAY = 24 hours;
/*LN-17*/     uint256 public constant LARGE_WITHDRAWAL_THRESHOLD = 10 ether;
/*LN-18*/ 
/*LN-19*/     struct PendingWithdrawal {
/*LN-20*/         address token;
/*LN-21*/         address to;
/*LN-22*/         uint256 amount;
/*LN-23*/         uint256 executeAfter;
/*LN-24*/         bool executed;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     mapping(bytes32 => PendingWithdrawal) public pendingWithdrawals;
/*LN-28*/ 
/*LN-29*/     event Withdrawal(address token, address to, uint256 amount);
/*LN-30*/     event WithdrawalQueued(bytes32 indexed id, address token, address to, uint256 amount, uint256 executeAfter);
/*LN-31*/ 
/*LN-32*/     constructor() {
/*LN-33*/         owner = msg.sender;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     modifier onlyOwner() {
/*LN-37*/         require(msg.sender == owner, "Not owner");
/*LN-38*/         _;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     function withdraw(
/*LN-42*/         address token,
/*LN-43*/         address to,
/*LN-44*/         uint256 amount
/*LN-45*/     ) external onlyOwner {
/*LN-46*/         if (amount >= LARGE_WITHDRAWAL_THRESHOLD) {
/*LN-47*/             bytes32 id = keccak256(abi.encodePacked(token, to, amount, block.timestamp));
/*LN-48*/             pendingWithdrawals[id] = PendingWithdrawal({
/*LN-49*/                 token: token,
/*LN-50*/                 to: to,
/*LN-51*/                 amount: amount,
/*LN-52*/                 executeAfter: block.timestamp + TIMELOCK_DELAY,
/*LN-53*/                 executed: false
/*LN-54*/             });
/*LN-55*/             emit WithdrawalQueued(id, token, to, amount, block.timestamp + TIMELOCK_DELAY);
/*LN-56*/             return;
/*LN-57*/         }
/*LN-58*/ 
/*LN-59*/         _executeWithdrawal(token, to, amount);
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/     function executeQueuedWithdrawal(bytes32 id) external onlyOwner {
/*LN-63*/         PendingWithdrawal storage pending = pendingWithdrawals[id];
/*LN-64*/         require(pending.executeAfter > 0, "Withdrawal not found");
/*LN-65*/         require(!pending.executed, "Already executed");
/*LN-66*/         require(block.timestamp >= pending.executeAfter, "Timelock not expired");
/*LN-67*/ 
/*LN-68*/         pending.executed = true;
/*LN-69*/         _executeWithdrawal(pending.token, pending.to, pending.amount);
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     function _executeWithdrawal(address token, address to, uint256 amount) internal {
/*LN-73*/         if (token == address(0)) {
/*LN-74*/             payable(to).transfer(amount);
/*LN-75*/         } else {
/*LN-76*/             IERC20(token).transfer(to, amount);
/*LN-77*/         }
/*LN-78*/ 
/*LN-79*/         emit Withdrawal(token, to, amount);
/*LN-80*/     }
/*LN-81*/ 
/*LN-82*/     function emergencyWithdraw(address token) external onlyOwner {
/*LN-83*/         uint256 balance;
/*LN-84*/         if (token == address(0)) {
/*LN-85*/             balance = address(this).balance;
/*LN-86*/         } else {
/*LN-87*/             balance = IERC20(token).balanceOf(address(this));
/*LN-88*/         }
/*LN-89*/ 
/*LN-90*/         // Emergency withdrawals also require timelock for large amounts
/*LN-91*/         if (balance >= LARGE_WITHDRAWAL_THRESHOLD) {
/*LN-92*/             bytes32 id = keccak256(abi.encodePacked(token, owner, balance, block.timestamp, "emergency"));
/*LN-93*/             pendingWithdrawals[id] = PendingWithdrawal({
/*LN-94*/                 token: token,
/*LN-95*/                 to: owner,
/*LN-96*/                 amount: balance,
/*LN-97*/                 executeAfter: block.timestamp + TIMELOCK_DELAY,
/*LN-98*/                 executed: false
/*LN-99*/             });
/*LN-100*/             emit WithdrawalQueued(id, token, owner, balance, block.timestamp + TIMELOCK_DELAY);
/*LN-101*/             return;
/*LN-102*/         }
/*LN-103*/ 
/*LN-104*/         _executeWithdrawal(token, owner, balance);
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     function transferOwnership(address newOwner) external onlyOwner {
/*LN-108*/         owner = newOwner;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     receive() external payable {}
/*LN-112*/ }
/*LN-113*/ 