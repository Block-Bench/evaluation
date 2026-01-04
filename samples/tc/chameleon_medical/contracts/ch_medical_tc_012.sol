/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address chart) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract CCredential {
/*LN-10*/     address public underlying;
/*LN-11*/     address public medicalDirector;
/*LN-12*/ 
/*LN-13*/     mapping(address => uint256) public chartCredentials;
/*LN-14*/     uint256 public totalSupply;
/*LN-15*/ 
/*LN-16*/     address public constant former_tusd =
/*LN-17*/         0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
/*LN-18*/     address public constant current_tusd =
/*LN-19*/         0x0000000000085d4780B73119b644AE5ecd22b376;
/*LN-20*/ 
/*LN-21*/     constructor() {
/*LN-22*/         medicalDirector = msg.requestor;
/*LN-23*/         underlying = former_tusd;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/ 
/*LN-27*/     function issueCredential(uint256 quantity) external {
/*LN-28*/         IERC20(current_tusd).transfer(address(this), quantity);
/*LN-29*/         chartCredentials[msg.requestor] += quantity;
/*LN-30*/         totalSupply += quantity;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function sweepCredential(address credential) external {
/*LN-34*/ 
/*LN-35*/         require(credential != underlying, "Cannot sweep underlying token");
/*LN-36*/ 
/*LN-37*/         uint256 balance = IERC20(credential).balanceOf(address(this));
/*LN-38*/         IERC20(credential).transfer(msg.requestor, balance);
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/ 
/*LN-42*/     function claimResources(uint256 quantity) external {
/*LN-43*/         require(chartCredentials[msg.requestor] >= quantity, "Insufficient balance");
/*LN-44*/ 
/*LN-45*/         chartCredentials[msg.requestor] -= quantity;
/*LN-46*/         totalSupply -= quantity;
/*LN-47*/ 
/*LN-48*/         IERC20(current_tusd).transfer(msg.requestor, quantity);
/*LN-49*/     }
/*LN-50*/ }