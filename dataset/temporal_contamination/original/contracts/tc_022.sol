/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * HUNDRED FINANCE EXPLOIT (March 2022)  
/*LN-6*/  * Attack: ERC667 Token Hooks Reentrancy
/*LN-7*/  * Loss: $6 million
/*LN-8*/  * 
/*LN-9*/  * ERC667 tokens have transfer hooks that call recipient contracts.
/*LN-10*/  * Hundred Finance (Compound fork) didn't account for reentrancy during
/*LN-11*/  * the token transfer, allowing attackers to re-enter and manipulate state.
/*LN-12*/  */
/*LN-13*/ 
/*LN-14*/ interface IERC20 {
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ interface ICompoundToken {
/*LN-20*/     function borrow(uint256 amount) external;
/*LN-21*/     function repayBorrow(uint256 amount) external;
/*LN-22*/     function redeem(uint256 tokens) external;
/*LN-23*/     function mint(uint256 amount) external;
/*LN-24*/ }
/*LN-25*/ 
/*LN-26*/ contract HundredFinanceMarket {
/*LN-27*/     mapping(address => uint256) public accountBorrows;
/*LN-28*/     mapping(address => uint256) public accountTokens;
/*LN-29*/     
/*LN-30*/     address public underlying;
/*LN-31*/     uint256 public totalBorrows;
/*LN-32*/     
/*LN-33*/     constructor(address _underlying) {
/*LN-34*/         underlying = _underlying;
/*LN-35*/     }
/*LN-36*/     
/*LN-37*/     function borrow(uint256 amount) external {
/*LN-38*/         accountBorrows[msg.sender] += amount;
/*LN-39*/         totalBorrows += amount;
/*LN-40*/         
/*LN-41*/         // VULNERABLE: Transfer before updating state completely
/*LN-42*/         // If underlying is ERC667, it can call back during transfer
/*LN-43*/         IERC20(underlying).transfer(msg.sender, amount);
/*LN-44*/     }
/*LN-45*/     
/*LN-46*/     function repayBorrow(uint256 amount) external {
/*LN-47*/         // Transfer tokens from user
/*LN-48*/         IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-49*/         
/*LN-50*/         // Update borrow state
/*LN-51*/         accountBorrows[msg.sender] -= amount;
/*LN-52*/         totalBorrows -= amount;
/*LN-53*/     }
/*LN-54*/ }
/*LN-55*/ 
/*LN-56*/ /**
/*LN-57*/  * EXPLOIT: 
/*LN-58*/  * 1. Flash loan ERC667 tokens
/*LN-59*/  * 2. Call borrow() 
/*LN-60*/  * 3. During transfer, ERC667 calls back to attacker
/*LN-61*/  * 4. Attacker re-enters borrow() before first borrow completes
/*LN-62*/  * 5. Can borrow multiple times with same collateral
/*LN-63*/  * 6. Drain $6M from protocol
/*LN-64*/  * 
/*LN-65*/  * Fix: Use reentrancy guards or checks-effects-interactions pattern
/*LN-66*/  */
/*LN-67*/ 