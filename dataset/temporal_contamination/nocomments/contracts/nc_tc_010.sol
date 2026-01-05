/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IComptroller {
/*LN-4*/     function enterMarkets(
/*LN-5*/         address[] memory cTokens
/*LN-6*/     ) external returns (uint256[] memory);
/*LN-7*/ 
/*LN-8*/     function exitMarket(address cToken) external returns (uint256);
/*LN-9*/ 
/*LN-10*/     function getAccountLiquidity(
/*LN-11*/         address account
/*LN-12*/     ) external view returns (uint256, uint256, uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LendingHub {
/*LN-16*/     IComptroller public comptroller;
/*LN-17*/ 
/*LN-18*/     mapping(address => uint256) public deposits;
/*LN-19*/     mapping(address => uint256) public borrowed;
/*LN-20*/     mapping(address => bool) public inMarket;
/*LN-21*/ 
/*LN-22*/     uint256 public totalDeposits;
/*LN-23*/     uint256 public totalBorrowed;
/*LN-24*/     uint256 public constant COLLATERAL_FACTOR = 150;
/*LN-25*/ 
/*LN-26*/     constructor(address _comptroller) {
/*LN-27*/         comptroller = IComptroller(_comptroller);
/*LN-28*/     }
/*LN-29*/ 
/*LN-30*/ 
/*LN-31*/     function depositAndEnterMarket() external payable {
/*LN-32*/         deposits[msg.sender] += msg.value;
/*LN-33*/         totalDeposits += msg.value;
/*LN-34*/         inMarket[msg.sender] = true;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/ 
/*LN-38*/     function isHealthy(
/*LN-39*/         address account,
/*LN-40*/         uint256 additionalBorrow
/*LN-41*/     ) public view returns (bool) {
/*LN-42*/         uint256 totalDebt = borrowed[account] + additionalBorrow;
/*LN-43*/         if (totalDebt == 0) return true;
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/         if (!inMarket[account]) return false;
/*LN-47*/ 
/*LN-48*/         uint256 collateralValue = deposits[account];
/*LN-49*/         return collateralValue >= (totalDebt * COLLATERAL_FACTOR) / 100;
/*LN-50*/     }
/*LN-51*/ 
/*LN-52*/     function borrow(uint256 amount) external {
/*LN-53*/         require(amount > 0, "Invalid amount");
/*LN-54*/         require(address(this).balance >= amount, "Insufficient funds");
/*LN-55*/ 
/*LN-56*/ 
/*LN-57*/         require(isHealthy(msg.sender, amount), "Insufficient collateral");
/*LN-58*/ 
/*LN-59*/ 
/*LN-60*/         borrowed[msg.sender] += amount;
/*LN-61*/         totalBorrowed += amount;
/*LN-62*/ 
/*LN-63*/         (bool success, ) = payable(msg.sender).call{value: amount}("");
/*LN-64*/         require(success, "Transfer failed");
/*LN-65*/ 
/*LN-66*/         require(isHealthy(msg.sender, 0), "Health check failed");
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function exitMarket() external {
/*LN-70*/         require(borrowed[msg.sender] == 0, "Outstanding debt");
/*LN-71*/         inMarket[msg.sender] = false;
/*LN-72*/     }
/*LN-73*/ 
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