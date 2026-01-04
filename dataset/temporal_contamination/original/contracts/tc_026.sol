/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * BELT FINANCE EXPLOIT (May 2021)
/*LN-6*/  * Attack: Strategy Vault Price Manipulation  
/*LN-7*/  * Loss: $6.2 million
/*LN-8*/  * 
/*LN-9*/  * Belt Finance vault strategies relied on manipulatable price oracles
/*LN-10*/  * for calculating share values during deposits/withdrawals.
/*LN-11*/  */
/*LN-12*/ 
/*LN-13*/ interface IERC20 {
/*LN-14*/     function balanceOf(address account) external view returns (uint256);
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ interface IPriceOracle {
/*LN-19*/     function getPrice(address token) external view returns (uint256);
/*LN-20*/ }
/*LN-21*/ 
/*LN-22*/ contract BeltStrategy {
/*LN-23*/     address public wantToken;
/*LN-24*/     address public oracle;
/*LN-25*/     uint256 public totalShares;
/*LN-26*/     
/*LN-27*/     mapping(address => uint256) public shares;
/*LN-28*/     
/*LN-29*/     constructor(address _want, address _oracle) {
/*LN-30*/         wantToken = _want;
/*LN-31*/         oracle = _oracle;
/*LN-32*/     }
/*LN-33*/     
/*LN-34*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
/*LN-35*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-36*/         
/*LN-37*/         if (totalShares == 0) {
/*LN-38*/             sharesAdded = amount;
/*LN-39*/         } else {
/*LN-40*/             // VULNERABLE: Price from oracle can be manipulated
/*LN-41*/             uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-42*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-43*/         }
/*LN-44*/         
/*LN-45*/         shares[msg.sender] += sharesAdded;
/*LN-46*/         totalShares += sharesAdded;
/*LN-47*/         
/*LN-48*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-49*/         return sharesAdded;
/*LN-50*/     }
/*LN-51*/     
/*LN-52*/     function withdraw(uint256 sharesAmount) external {
/*LN-53*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-54*/         
/*LN-55*/         // VULNERABLE: Uses manipulated price
/*LN-56*/         uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-57*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-58*/         
/*LN-59*/         shares[msg.sender] -= sharesAmount;
/*LN-60*/         totalShares -= sharesAmount;
/*LN-61*/         
/*LN-62*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-63*/     }
/*LN-64*/ }
/*LN-65*/ 
/*LN-66*/ /**
/*LN-67*/  * EXPLOIT:
/*LN-68*/  * 1. Flash loan to manipulate oracle price down
/*LN-69*/  * 2. Deposit when price is low (get more shares)
/*LN-70*/  * 3. Manipulate price back up
/*LN-71*/  * 4. Withdraw with inflated share value  
/*LN-72*/  * 5. Profit $6.2M from price manipulation
/*LN-73*/  * 
/*LN-74*/  * Fix: Use TWAP oracles, manipulation-resistant pricing
/*LN-75*/  */
/*LN-76*/ 