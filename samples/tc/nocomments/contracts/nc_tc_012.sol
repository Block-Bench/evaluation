/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract CToken {
/*LN-10*/     address public underlying;
/*LN-11*/     address public admin;
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public accountTokens;
/*LN-14*/     uint256 public totalSupply;
/*LN-15*/ 
/*LN-16*/     address public constant OLD_TUSD =
/*LN-17*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-18*/     address public constant NEW_TUSD =
/*LN-19*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-20*/ 
/*LN-21*/     constructor() {
/*LN-22*/         admin = msg.sender;
/*LN-23*/         underlying = OLD_TUSD;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/ 
/*LN-27*/     function mint(uint256 amount) external {
/*LN-28*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-29*/         accountTokens[msg.sender] += amount;
/*LN-30*/         totalSupply += amount;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function sweepToken(address token) external {
/*LN-34*/ 
/*LN-35*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-36*/ 
/*LN-37*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-38*/         IERC20(token).transfer(msg.sender, balance);
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/     function redeem(uint256 amount) external {
/*LN-43*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-44*/ 
/*LN-45*/         accountTokens[msg.sender] -= amount;
/*LN-46*/         totalSupply -= amount;
/*LN-47*/ 
/*LN-48*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-49*/     }
/*LN-50*/ }