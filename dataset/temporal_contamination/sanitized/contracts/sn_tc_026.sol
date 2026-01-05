/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface IPriceOracle {
/*LN-10*/     function getPrice(address token) external view returns (uint256);
/*LN-11*/ }
/*LN-12*/ 
/*LN-13*/ contract YieldStrategy {
/*LN-14*/     address public wantToken;
/*LN-15*/     address public oracle;
/*LN-16*/     uint256 public totalShares;
/*LN-17*/ 
/*LN-18*/     mapping(address => uint256) public shares;
/*LN-19*/ 
/*LN-20*/     constructor(address _want, address _oracle) {
/*LN-21*/         wantToken = _want;
/*LN-22*/         oracle = _oracle;
/*LN-23*/     }
/*LN-24*/ 
/*LN-25*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
/*LN-26*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-27*/ 
/*LN-28*/         if (totalShares == 0) {
/*LN-29*/             sharesAdded = amount;
/*LN-30*/         } else {
/*LN-31*/             uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-32*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-33*/         }
/*LN-34*/ 
/*LN-35*/         shares[msg.sender] += sharesAdded;
/*LN-36*/         totalShares += sharesAdded;
/*LN-37*/ 
/*LN-38*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-39*/         return sharesAdded;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function withdraw(uint256 sharesAmount) external {
/*LN-43*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-44*/ 
/*LN-45*/         uint256 price = IPriceOracle(oracle).getPrice(wantToken);
/*LN-46*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-47*/ 
/*LN-48*/         shares[msg.sender] -= sharesAmount;
/*LN-49*/         totalShares -= sharesAmount;
/*LN-50*/ 
/*LN-51*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-52*/     }
/*LN-53*/ }
/*LN-54*/ 