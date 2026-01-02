/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ /**
/*LN-11*/  */
/*LN-12*/ contract FloatHotWalletV2 {
/*LN-13*/     address public owner;
/*LN-14*/ 
/*LN-15*/     mapping(address => bool) public authorizedOperators;
/*LN-16*/ 
/*LN-17*/     event Withdrawal(address token, address to, uint256 amount);
/*LN-18*/ 
/*LN-19*/     constructor() {
/*LN-20*/         owner = msg.sender;
/*LN-21*/     }
/*LN-22*/ 
/*LN-23*/     /**
/*LN-24*/      */
/*LN-25*/     modifier onlyOwner() {
/*LN-26*/         require(msg.sender == owner, "Not owner");
/*LN-27*/         _;
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/     /**
/*LN-31*/      */
/*LN-32*/     function withdraw(
/*LN-33*/         address token,
/*LN-34*/         address to,
/*LN-35*/         uint256 amount
/*LN-36*/     ) external onlyOwner {
/*LN-37*/ 
/*LN-38*/         if (token == address(0)) {
/*LN-39*/             // Withdraw ETH
/*LN-40*/             payable(to).transfer(amount);
/*LN-41*/         } else {
/*LN-42*/             // Withdraw ERC20 tokens
/*LN-43*/             IERC20(token).transfer(to, amount);
/*LN-44*/         }
/*LN-45*/ 
/*LN-46*/         emit Withdrawal(token, to, amount);
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      */
/*LN-51*/     function emergencyWithdraw(address token) external onlyOwner {
/*LN-52*/ 
/*LN-53*/         uint256 balance;
/*LN-54*/         if (token == address(0)) {
/*LN-55*/             balance = address(this).balance;
/*LN-56*/             payable(owner).transfer(balance);
/*LN-57*/         } else {
/*LN-58*/             balance = IERC20(token).balanceOf(address(this));
/*LN-59*/             IERC20(token).transfer(owner, balance);
/*LN-60*/         }
/*LN-61*/ 
/*LN-62*/         emit Withdrawal(token, owner, balance);
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     /**
/*LN-66*/      * @dev Transfer ownership - critical function with no protection
/*LN-67*/      */
/*LN-68*/     function transferOwnership(address newOwner) external onlyOwner {
/*LN-69*/         owner = newOwner;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     receive() external payable {}
/*LN-73*/ }
/*LN-74*/ 