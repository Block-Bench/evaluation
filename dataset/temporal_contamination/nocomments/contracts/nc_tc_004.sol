/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IStablePool {
/*LN-4*/     function exchange_underlying(
/*LN-5*/         int128 i,
/*LN-6*/         int128 j,
/*LN-7*/         uint256 dx,
/*LN-8*/         uint256 min_dy
/*LN-9*/     ) external returns (uint256);
/*LN-10*/ 
/*LN-11*/     function get_dy_underlying(
/*LN-12*/         int128 i,
/*LN-13*/         int128 j,
/*LN-14*/         uint256 dx
/*LN-15*/     ) external view returns (uint256);
/*LN-16*/ }
/*LN-17*/ 
/*LN-18*/ contract YieldVault {
/*LN-19*/     address public underlyingToken;
/*LN-20*/     IStablePool public stablePool;
/*LN-21*/ 
/*LN-22*/     uint256 public totalSupply;
/*LN-23*/     mapping(address => uint256) public balanceOf;
/*LN-24*/ 
/*LN-25*/ 
/*LN-26*/     uint256 public investedBalance;
/*LN-27*/ 
/*LN-28*/     event Deposit(address indexed user, uint256 amount, uint256 shares);
/*LN-29*/     event Withdrawal(address indexed user, uint256 shares, uint256 amount);
/*LN-30*/ 
/*LN-31*/     constructor(address _token, address _stablePool) {
/*LN-32*/         underlyingToken = _token;
/*LN-33*/         stablePool = IStablePool(_stablePool);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function deposit(uint256 amount) external returns (uint256 shares) {
/*LN-37*/         require(amount > 0, "Zero amount");
/*LN-38*/ 
/*LN-39*/ 
/*LN-40*/         if (totalSupply == 0) {
/*LN-41*/             shares = amount;
/*LN-42*/         } else {
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/             uint256 totalAssets = getTotalAssets();
/*LN-46*/             shares = (amount * totalSupply) / totalAssets;
/*LN-47*/         }
/*LN-48*/ 
/*LN-49*/         balanceOf[msg.sender] += shares;
/*LN-50*/         totalSupply += shares;
/*LN-51*/ 
/*LN-52*/         _investInPool(amount);
/*LN-53*/ 
/*LN-54*/         emit Deposit(msg.sender, amount, shares);
/*LN-55*/         return shares;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function withdraw(uint256 shares) external returns (uint256 amount) {
/*LN-59*/         require(shares > 0, "Zero shares");
/*LN-60*/         require(balanceOf[msg.sender] >= shares, "Insufficient balance");
/*LN-61*/ 
/*LN-62*/ 
/*LN-63*/         uint256 totalAssets = getTotalAssets();
/*LN-64*/         amount = (shares * totalAssets) / totalSupply;
/*LN-65*/ 
/*LN-66*/         balanceOf[msg.sender] -= shares;
/*LN-67*/         totalSupply -= shares;
/*LN-68*/ 
/*LN-69*/         _withdrawFromPool(amount);
/*LN-70*/ 
/*LN-71*/ 
/*LN-72*/         emit Withdrawal(msg.sender, shares, amount);
/*LN-73*/         return amount;
/*LN-74*/     }
/*LN-75*/ 
/*LN-76*/     function getTotalAssets() public view returns (uint256) {
/*LN-77*/ 
/*LN-78*/         uint256 vaultBalance = 0;
/*LN-79*/         uint256 poolBalance = investedBalance;
/*LN-80*/ 
/*LN-81*/         return vaultBalance + poolBalance;
/*LN-82*/     }
/*LN-83*/ 
/*LN-84*/     function getPricePerFullShare() public view returns (uint256) {
/*LN-85*/         if (totalSupply == 0) return 1e18;
/*LN-86*/         return (getTotalAssets() * 1e18) / totalSupply;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/     function _investInPool(uint256 amount) internal {
/*LN-91*/         investedBalance += amount;
/*LN-92*/ 
/*LN-93*/ 
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function _withdrawFromPool(uint256 amount) internal {
/*LN-98*/         require(investedBalance >= amount, "Insufficient invested");
/*LN-99*/         investedBalance -= amount;
/*LN-100*/ 
/*LN-101*/ 
/*LN-102*/     }
/*LN-103*/ }