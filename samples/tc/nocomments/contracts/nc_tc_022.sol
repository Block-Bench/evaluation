/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ interface ILendToken {
/*LN-9*/     function borrow(uint256 amount) external;
/*LN-10*/     function repayBorrow(uint256 amount) external;
/*LN-11*/     function redeem(uint256 tokens) external;
/*LN-12*/     function mint(uint256 amount) external;
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LendingMarket {
/*LN-16*/     mapping(address => uint256) public accountBorrows;
/*LN-17*/     mapping(address => uint256) public accountTokens;
/*LN-18*/ 
/*LN-19*/     address public underlying;
/*LN-20*/     uint256 public totalBorrows;
/*LN-21*/ 
/*LN-22*/     constructor(address _underlying) {
/*LN-23*/         underlying = _underlying;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/     function borrow(uint256 amount) external {
/*LN-27*/         accountBorrows[msg.sender] += amount;
/*LN-28*/         totalBorrows += amount;
/*LN-29*/ 
/*LN-30*/         IERC20(underlying).transfer(msg.sender, amount);
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function repayBorrow(uint256 amount) external {
/*LN-34*/ 
/*LN-35*/         IERC20(underlying).transferFrom(msg.sender, address(this), amount);
/*LN-36*/ 
/*LN-37*/ 
/*LN-38*/         accountBorrows[msg.sender] -= amount;
/*LN-39*/         totalBorrows -= amount;
/*LN-40*/     }
/*LN-41*/ }