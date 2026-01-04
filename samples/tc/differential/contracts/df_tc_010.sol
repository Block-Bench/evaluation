/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Lending Protocol
/*LN-6*/  * @notice Manages collateral deposits and borrowing
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IComptroller {
/*LN-10*/     function enterMarkets(
/*LN-11*/         address[] memory cTokens
/*LN-12*/     ) external returns (uint256[] memory);
/*LN-13*/ 
/*LN-14*/     function exitMarket(address cToken) external returns (uint256);
/*LN-15*/ 
/*LN-16*/     function getAccountLiquidity(
/*LN-17*/         address account
/*LN-18*/     ) external view returns (uint256, uint256, uint256);
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract LendingProtocol {
/*LN-22*/     IComptroller public comptroller;
/*LN-23*/ 
/*LN-24*/     mapping(address => uint256) public deposits;
/*LN-25*/     mapping(address => uint256) public borrowed;
/*LN-26*/     mapping(address => bool) public inMarket;
/*LN-27*/ 
/*LN-28*/     uint256 public totalDeposits;
/*LN-29*/     uint256 public totalBorrowed;
/*LN-30*/     uint256 public constant COLLATERAL_FACTOR = 150;
/*LN-31*/ 
/*LN-32*/     constructor(address _comptroller) {
/*LN-33*/         comptroller = IComptroller(_comptroller);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function depositAndEnterMarket() external payable {
/*LN-37*/         deposits[msg.sender] += msg.value;
/*LN-38*/         totalDeposits += msg.value;
/*LN-39*/         inMarket[msg.sender] = true;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function isHealthy(
/*LN-43*/         address account,
/*LN-44*/         uint256 additionalBorrow
/*LN-45*/     ) public view returns (bool) {
/*LN-46*/         uint256 totalDebt = borrowed[account] + additionalBorrow;
/*LN-47*/         if (totalDebt == 0) return true;
/*LN-48*/ 
/*LN-49*/         if (!inMarket[account]) return false;
/*LN-50*/ 
/*LN-51*/         uint256 collateralValue = deposits[account];
/*LN-52*/         return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     function borrow(uint256 amount) external {
/*LN-56*/         require(amount > 0, "Invalid amount");
/*LN-57*/         require(address(this).balance >= amount, "Insufficient funds");
/*LN-58*/ 
/*LN-59*/         require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-60*/ 
/*LN-61*/         borrowed[msg.sender] += amount;
/*LN-62*/         totalBorrowed += amount;
/*LN-63*/ 
/*LN-64*/         require(isHealthy(msg.sender, 0), "Health check failed");
/*LN-65*/ 
/*LN-66*/         (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-67*/         require(success, "Transfer failed");
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/     function exitMarket() external {
/*LN-71*/         require(borrowed[msg.sender] == 0, "Outstanding debt");
/*LN-72*/         inMarket[msg.sender] = false;
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/     function withdraw(uint256 amount) external {
/*LN-76*/         require(deposits[msg.sender] >= amount, "Insufficient deposits");
/*LN-77*/         require(!inMarket[msg.sender], "Exit market first");
/*LN-78*/ 
/*LN-79*/         deposits[msg.sender] -= amount;
/*LN-80*/         totalDeposits -= amount;
/*LN-81*/ 
/*LN-82*/         payable(msg.sender).transfer(amount);
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     receive() external payable {}
/*LN-86*/ }
/*LN-87*/ 