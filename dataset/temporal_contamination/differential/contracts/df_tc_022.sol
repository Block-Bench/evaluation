/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface ICompoundToken {
/*LN-10*/     function borrow(uint256 amount) external;
/*LN-11*/     function repayBorrow(uint256 amount) external;
/*LN-12*/     function redeem(uint256 tokens) external;
/*LN-13*/     function mint(uint256 amount) external;
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract LendingMarket {
/*LN-17*/     mapping(address => uint256) public accountBorrows;
/*LN-18*/     mapping(address => uint256) public accountTokens;
/*LN-19*/ 
/*LN-20*/     address public underlying;
/*LN-21*/     uint256 public totalBorrows;
/*LN-22*/ 
/*LN-23*/     bool private _locked;
/*LN-24*/ 
/*LN-25*/     modifier nonReentrant() {
/*LN-26*/         require(!_locked, "Reentrant call");
/*LN-27*/         _locked = true;
/*LN-28*/         _;
/*LN-29*/         _locked = false;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/     constructor(address _underlying) {
/*LN-33*/         underlying = _underlying;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function borrow(uint256 amount) external nonReentrant {
/*LN-37*/         accountBorrows[msg.sender] += amount;
/*LN-38*/         totalBorrows += amount;
/*LN-39*/ 
/*LN-40*/         IERC20(underlying).transfer(msg.sender, amount);
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function repayBorrow(uint256 amount) external {
/*LN-44*/         IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-45*/ 
/*LN-46*/         accountBorrows[msg.sender] -= amount;
/*LN-47*/         totalBorrows -= amount;
/*LN-48*/     }
/*LN-49*/ }
/*LN-50*/ 