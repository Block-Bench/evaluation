/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract CToken {
/*LN-11*/     address public underlying; // Old TUSD address
/*LN-12*/     address public admin;
/*LN-13*/ 
/*LN-14*/     mapping(address => uint256) public accountTokens;
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/ 
/*LN-17*/     address public constant OLD_TUSD =
/*LN-18*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-19*/     address public constant NEW_TUSD =
/*LN-20*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-21*/ 
/*LN-22*/     constructor() {
/*LN-23*/         admin = msg.sender;
/*LN-24*/         underlying = OLD_TUSD;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     /**
/*LN-28*/      * @notice Supply tokens to the market
/*LN-29*/      */
/*LN-30*/     function mint(uint256 amount) external {
/*LN-31*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-32*/         accountTokens[msg.sender] += amount;
/*LN-33*/         totalSupply += amount;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function sweepToken(address token) external {
/*LN-37*/ 
/*LN-38*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-39*/ 
/*LN-40*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-41*/         IERC20(token).transfer(msg.sender, balance);
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     /**
/*LN-45*/      * @notice Redeem cTokens for underlying
/*LN-46*/      */
/*LN-47*/     function redeem(uint256 amount) external {
/*LN-48*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-49*/ 
/*LN-50*/         accountTokens[msg.sender] -= amount;
/*LN-51*/         totalSupply -= amount;
/*LN-52*/ 
/*LN-53*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-54*/     }
/*LN-55*/ }
/*LN-56*/ 