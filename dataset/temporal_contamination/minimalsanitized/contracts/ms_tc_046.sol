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
/*LN-12*/ contract FixedFloatHotWallet {
/*LN-13*/     address public owner;
/*LN-14*/ 
/*LN-15*/     
/*LN-16*/ 
/*LN-17*/     mapping(address => bool) public authorizedOperators;
/*LN-18*/ 
/*LN-19*/     event Withdrawal(address token, address to, uint256 amount);
/*LN-20*/ 
/*LN-21*/     constructor() {
/*LN-22*/         owner = msg.sender;
/*LN-23*/     }
/*LN-24*/ 
/*LN-25*/     /**
/*LN-26*/      */
/*LN-27*/     modifier onlyOwner() {
/*LN-28*/         require(msg.sender == owner, "Not owner");
/*LN-29*/         _;
/*LN-30*/     }
/*LN-31*/ 
/*LN-32*/     /**
/*LN-33*/      */
/*LN-34*/     function withdraw(
/*LN-35*/         address token,
/*LN-36*/         address to,
/*LN-37*/         uint256 amount
/*LN-38*/     ) external onlyOwner {
/*LN-39*/ 
/*LN-40*/         if (token == address(0)) {
/*LN-41*/             // Withdraw ETH
/*LN-42*/             payable(to).transfer(amount);
/*LN-43*/         } else {
/*LN-44*/             // Withdraw ERC20 tokens
/*LN-45*/             IERC20(token).transfer(to, amount);
/*LN-46*/         }
/*LN-47*/ 
/*LN-48*/         emit Withdrawal(token, to, amount);
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     /**
/*LN-52*/      */
/*LN-53*/     function emergencyWithdraw(address token) external onlyOwner {
/*LN-54*/ 
/*LN-55*/         uint256 balance;
/*LN-56*/         if (token == address(0)) {
/*LN-57*/             balance = address(this).balance;
/*LN-58*/             payable(owner).transfer(balance);
/*LN-59*/         } else {
/*LN-60*/             balance = IERC20(token).balanceOf(address(this));
/*LN-61*/             IERC20(token).transfer(owner, balance);
/*LN-62*/         }
/*LN-63*/ 
/*LN-64*/         emit Withdrawal(token, owner, balance);
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     /**
/*LN-68*/      * @dev Transfer ownership - critical function with no protection
/*LN-69*/      */
/*LN-70*/     function transferOwnership(address newOwner) external onlyOwner {
/*LN-71*/         owner = newOwner;
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     receive() external payable {}
/*LN-75*/ }
/*LN-76*/ 