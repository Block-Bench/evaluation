/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ interface IPriceOracle {
/*LN-9*/     function getPrice(address token) external view returns (uint256);
/*LN-10*/ }
/*LN-11*/ 
/*LN-12*/ contract YieldStrategy {
/*LN-13*/     address public wantToken;
/*LN-14*/     address public oracle;
/*LN-15*/     uint256 public totalShares;
/*LN-16*/ 
/*LN-17*/     mapping(address => uint256) public shares;
/*LN-18*/ 
/*LN-19*/     constructor(address _want, address _oracle) {
/*LN-20*/         wantToken = _want;
/*LN-21*/         oracle = _oracle;
/*LN-22*/     }
/*LN-23*/ 
/*LN-24*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
/*LN-25*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-26*/ 
/*LN-27*/         if (totalShares == 0) {
/*LN-28*/             sharesAdded = amount;
/*LN-29*/         } else {
/*LN-30*/             uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-31*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-32*/         }
/*LN-33*/ 
/*LN-34*/         shares[msg.sender] += sharesAdded;
/*LN-35*/         totalShares += sharesAdded;
/*LN-36*/ 
/*LN-37*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-38*/         return sharesAdded;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     function withdraw(uint256 sharesAmount) external {
/*LN-42*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-43*/ 
/*LN-44*/         uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-45*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-46*/ 
/*LN-47*/         shares[msg.sender] -= sharesAmount;
/*LN-48*/         totalShares -= sharesAmount;
/*LN-49*/ 
/*LN-50*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-51*/     }
/*LN-52*/ }