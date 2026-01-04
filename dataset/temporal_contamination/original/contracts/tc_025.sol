/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * BVAULTS (SAFEMOON) EXPLOIT (May 2021)
/*LN-6*/  * Attack: Liquidity Pool Drain via Token Manipulation
/*LN-7*/  * Loss: $8.5 million
/*LN-8*/  * 
/*LN-9*/  * SafeMoon-style tokens with transfer fees/burns can be exploited
/*LN-10*/  * when pools don't account for the actual received amounts.
/*LN-11*/  */
/*LN-12*/ 
/*LN-13*/ interface IERC20 {
/*LN-14*/     function balanceOf(address account) external view returns (uint256);
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-17*/ }
/*LN-18*/ 
/*LN-19*/ contract DeflatToken {
/*LN-20*/     mapping(address => uint256) public balanceOf;
/*LN-21*/     uint256 public totalSupply;
/*LN-22*/     uint256 public feePercent = 10; // 10% burn on transfer
/*LN-23*/     
/*LN-24*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-25*/         uint256 fee = (amount * feePercent) / 100;
/*LN-26*/         uint256 amountAfterFee = amount - fee;
/*LN-27*/         
/*LN-28*/         balanceOf[msg.sender] -= amount;
/*LN-29*/         balanceOf[to] += amountAfterFee;
/*LN-30*/         totalSupply -= fee; // Burn fee
/*LN-31*/         
/*LN-32*/         return true;
/*LN-33*/     }
/*LN-34*/     
/*LN-35*/     function transferFrom(address from, address to, uint256 amount) external returns (bool) {
/*LN-36*/         uint256 fee = (amount * feePercent) / 100;
/*LN-37*/         uint256 amountAfterFee = amount - fee;
/*LN-38*/         
/*LN-39*/         balanceOf[from] -= amount;
/*LN-40*/         balanceOf[to] += amountAfterFee;
/*LN-41*/         totalSupply -= fee;
/*LN-42*/         
/*LN-43*/         return true;
/*LN-44*/     }
/*LN-45*/ }
/*LN-46*/ 
/*LN-47*/ contract VulnerableVault {
/*LN-48*/     address public token;
/*LN-49*/     mapping(address => uint256) public deposits;
/*LN-50*/     
/*LN-51*/     constructor(address _token) {
/*LN-52*/         token = _token;
/*LN-53*/     }
/*LN-54*/     
/*LN-55*/     function deposit(uint256 amount) external {
/*LN-56*/         // VULNERABLE: Assumes full amount is received
/*LN-57*/         // Doesn't check actual balance increase
/*LN-58*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-59*/         
/*LN-60*/         deposits[msg.sender] += amount; // Records full amount
/*LN-61*/         // But only received amount - fee!
/*LN-62*/     }
/*LN-63*/     
/*LN-64*/     function withdraw(uint256 amount) external {
/*LN-65*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-66*/         
/*LN-67*/         deposits[msg.sender] -= amount;
/*LN-68*/         
/*LN-69*/         // VULNERABILITY: Transfers full amount user deposited
/*LN-70*/         // But vault actually received less due to transfer fee
/*LN-71*/         IERC20(token).transfer(msg.sender, amount);
/*LN-72*/     }
/*LN-73*/ }
/*LN-74*/ 
/*LN-75*/ /**
/*LN-76*/  * EXPLOIT:
/*LN-77*/  * 1. Deflation token charges 10% fee on transfers
/*LN-78*/  * 2. Attacker deposits 100 tokens
/*LN-79*/  * 3. Vault receives only 90 tokens (10% burned)
/*LN-80*/  * 4. Vault credits attacker with 100 tokens in deposits[]
/*LN-81*/  * 5. Attacker withdraws 100 tokens
/*LN-82*/  * 6. Vault sends 100 tokens (but had 90 + others' deposits)
/*LN-83*/  * 7. Repeat to drain $8.5M from vault
/*LN-84*/  * 
/*LN-85*/  * Fix: Check actual balance before/after transfer:
/*LN-86*/  * uint256 balBefore = token.balanceOf(address(this));
/*LN-87*/  * token.transferFrom(...);
/*LN-88*/  * uint256 received = token.balanceOf(address(this)) - balBefore;
/*LN-89*/  * deposits[msg.sender] += received;
/*LN-90*/  */
/*LN-91*/ 