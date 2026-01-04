/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract CompoundCToken {
/*LN-11*/     address public underlying; // Old TUSD address
/*LN-12*/     address public admin;
/*LN-13*/ 
/*LN-14*/     mapping(address => uint256) public accountTokens;
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/ 
/*LN-17*/     
/*LN-18*/     address public constant OLD_TUSD =
/*LN-19*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-20*/     address public constant NEW_TUSD =
/*LN-21*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-22*/ 
/*LN-23*/     constructor() {
/*LN-24*/         admin = msg.sender;
/*LN-25*/         underlying = OLD_TUSD; 
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     /**
/*LN-29*/      * @notice Supply tokens to the market
/*LN-30*/      */
/*LN-31*/     function mint(uint256 amount) external {
/*LN-32*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-33*/         accountTokens[msg.sender] += amount;
/*LN-34*/         totalSupply += amount;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function sweepToken(address token) external {
/*LN-38*/         
/*LN-39*/         require(token != underlying, "Cannot sweep underlying token");
/*LN-40*/ 
/*LN-41*/        
/*LN-42*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-43*/         IERC20(token).transfer(msg.sender, balance);
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     /**
/*LN-47*/      * @notice Redeem cTokens for underlying
/*LN-48*/      */
/*LN-49*/     function redeem(uint256 amount) external {
/*LN-50*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-51*/ 
/*LN-52*/         accountTokens[msg.sender] -= amount;
/*LN-53*/         totalSupply -= amount;
/*LN-54*/ 
/*LN-55*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-56*/     }
/*LN-57*/ }
/*LN-58*/ 