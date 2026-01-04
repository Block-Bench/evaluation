/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Compound Market Token
/*LN-6*/  * @notice Represents claims on supplied assets
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract CompoundMarket {
/*LN-16*/     address public underlying;
/*LN-17*/     address public admin;
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public accountTokens;
/*LN-20*/     uint256 public totalSupply;
/*LN-21*/ 
/*LN-22*/     address public constant OLD_TUSD =
/*LN-23*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-24*/     address public constant NEW_TUSD =
/*LN-25*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-26*/ 
/*LN-27*/     mapping(address => bool) public validUnderlying;
/*LN-28*/ 
/*LN-29*/     constructor() {
/*LN-30*/         admin = msg.sender;
/*LN-31*/         underlying = NEW_TUSD;
/*LN-32*/         validUnderlying[OLD_TUSD] = true;
/*LN-33*/         validUnderlying[NEW_TUSD] = true;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function mint(uint256 amount) external {
/*LN-37*/         require(validUnderlying[NEW_TUSD], "Invalid underlying");
/*LN-38*/         IERC20(NEW_TUSD).transfer(address(this), amount);
/*LN-39*/         accountTokens[msg.sender] += amount;
/*LN-40*/         totalSupply += amount;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function sweepToken(address token) external {
/*LN-44*/         require(!validUnderlying[token], "Cannot sweep underlying token");
/*LN-45*/ 
/*LN-46*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-47*/         IERC20(token).transfer(msg.sender, balance);
/*LN-48*/     }
/*LN-49*/ 
/*LN-50*/     function redeem(uint256 amount) external {
/*LN-51*/         require(accountTokens[msg.sender] >= amount, "Insufficient balance");
/*LN-52*/ 
/*LN-53*/         accountTokens[msg.sender] -= amount;
/*LN-54*/         totalSupply -= amount;
/*LN-55*/ 
/*LN-56*/         IERC20(NEW_TUSD).transfer(msg.sender, amount);
/*LN-57*/     }
/*LN-58*/ }
/*LN-59*/ 