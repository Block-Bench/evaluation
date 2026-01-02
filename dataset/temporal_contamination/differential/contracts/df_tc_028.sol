/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract TokenVault {
/*LN-11*/     address public token;
/*LN-12*/     mapping(address => uint256) public deposits;
/*LN-13*/     
/*LN-14*/     constructor(address _token) {
/*LN-15*/         token = _token;
/*LN-16*/     }
/*LN-17*/     
/*LN-18*/     function deposit(uint256 amount) external {
/*LN-19*/         uint256 balBefore = IERC20(token).balanceOf(address(this));
/*LN-20*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-21*/         uint256 balAfter = IERC20(token).balanceOf(address(this));
/*LN-22*/         uint256 received = balAfter - balBefore;
/*LN-23*/         
/*LN-24*/         deposits[msg.sender] += received;
/*LN-25*/     }
/*LN-26*/     
/*LN-27*/     function withdraw(uint256 amount) external {
/*LN-28*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-29*/         
/*LN-30*/         deposits[msg.sender] -= amount;
/*LN-31*/         
/*LN-32*/         IERC20(token).transfer(msg.sender, amount);
/*LN-33*/     }
/*LN-34*/ }
/*LN-35*/ 