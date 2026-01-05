/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IComptroller {
/*LN-5*/     function enterMarkets(
/*LN-6*/         address[] memory cTokens
/*LN-7*/     ) external returns (uint256[] memory);
/*LN-8*/ 
/*LN-9*/     function exitMarket(address cToken) external returns (uint256);
/*LN-10*/ 
/*LN-11*/     function getAccountLiquidity(
/*LN-12*/         address account
/*LN-13*/     ) external view returns (uint256, uint256, uint256);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ contract RariFuse {
/*LN-17*/     IComptroller public comptroller;
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public deposits;
/*LN-20*/     mapping(address => uint256) public borrowed;
/*LN-21*/     mapping(address => bool) public inMarket;
/*LN-22*/ 
/*LN-23*/     uint256 public totalDeposits;
/*LN-24*/     uint256 public totalBorrowed;
/*LN-25*/     uint256 public constant COLLATERAL_FACTOR = 150; // 150% collateralization
/*LN-26*/ 
/*LN-27*/     constructor(address _comptroller) {
/*LN-28*/         comptroller = IComptroller(_comptroller);
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     /**
/*LN-32*/      * @notice Deposit collateral and enter market
/*LN-33*/      */
/*LN-34*/     function depositAndEnterMarket() external payable {
/*LN-35*/         deposits[msg.sender] += msg.value;
/*LN-36*/         totalDeposits += msg.value;
/*LN-37*/         inMarket[msg.sender] = true;
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/     /**
/*LN-41*/      * @notice Check if account has sufficient collateral
/*LN-42*/      */
/*LN-43*/     function isHealthy(
/*LN-44*/         address account,
/*LN-45*/         uint256 additionalBorrow
/*LN-46*/     ) public view returns (bool) {
/*LN-47*/         uint256 totalDebt = borrowed[account] + additionalBorrow;
/*LN-48*/         if (totalDebt == 0) return true;
/*LN-49*/ 
/*LN-50*/         // Only count deposits if user is in market
/*LN-51*/         if (!inMarket[account]) return false;
/*LN-52*/ 
/*LN-53*/         uint256 collateralValue = deposits[account];
/*LN-54*/         return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/     function borrow(uint256 amount) external {
/*LN-58*/         require(amount > 0, "Invalid amount");
/*LN-59*/         require(address(this).balance >= amount, "Insufficient funds");
/*LN-60*/ 
/*LN-61*/         // Initial health check
/*LN-62*/         require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-63*/ 
/*LN-64*/         // Update state
/*LN-65*/         borrowed[msg.sender] += amount;
/*LN-66*/         totalBorrowed += amount;
/*LN-67*/ 
/*LN-68*/         (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-69*/         require(success, "Transfer failed");
/*LN-70*/ 
/*LN-71*/         require(isHealthy(msg.sender, 0), "Health check failed");
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     function exitMarket() external {
/*LN-75*/         require(borrowed[msg.sender] == 0, "Outstanding debt");
/*LN-76*/         inMarket[msg.sender] = false;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     /**
/*LN-80*/      * @notice Withdraw collateral
/*LN-81*/      */
/*LN-82*/     function withdraw(uint256 amount) external {
/*LN-83*/         require(deposits[msg.sender] >= amount, "Insufficient deposits");
/*LN-84*/         require(!inMarket[msg.sender], "Exit market first");
/*LN-85*/ 
/*LN-86*/         deposits[msg.sender] -= amount;
/*LN-87*/         totalDeposits -= amount;
/*LN-88*/ 
/*LN-89*/         payable(msg.sender).transfer(amount);
/*LN-90*/     }
/*LN-91*/ 
/*LN-92*/     receive() external payable {}
/*LN-93*/ }
/*LN-94*/ 