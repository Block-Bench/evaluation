/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ interface ITWAPOracle {
/*LN-11*/     function getTWAP(address token) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract VaultStrategy {
/*LN-15*/     address public wantToken;
/*LN-16*/     address public oracle;
/*LN-17*/     uint256 public totalShares;
/*LN-18*/     
/*LN-19*/     mapping(address => uint256) public shares;
/*LN-20*/     
/*LN-21*/     constructor(address _want, address _oracle) {
/*LN-22*/         wantToken = _want;
/*LN-23*/         oracle = _oracle;
/*LN-24*/     }
/*LN-25*/     
/*LN-26*/     function deposit(uint256 amount) external returns (uint256 sharesAdded) {
/*LN-27*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-28*/         
/*LN-29*/         if (totalShares == 0) {
/*LN-30*/             sharesAdded = amount;
/*LN-31*/         } else {
/*LN-32*/             uint256 price = ITWAPOracle(oracle).getTWAP(wantToken);
/*LN-33*/             sharesAdded = (amount * totalShares * 1e18) / (pool * price);
/*LN-34*/         }
/*LN-35*/         
/*LN-36*/         shares[msg.sender] += sharesAdded;
/*LN-37*/         totalShares += sharesAdded;
/*LN-38*/         
/*LN-39*/         IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
/*LN-40*/         return sharesAdded;
/*LN-41*/     }
/*LN-42*/     
/*LN-43*/     function withdraw(uint256 sharesAmount) external {
/*LN-44*/         uint256 pool = IERC20(wantToken).balanceOf(address(this));
/*LN-45*/         
/*LN-46*/         uint256 price = ITWAPOracle(oracle).getTWAP(wantToken);
/*LN-47*/         uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
/*LN-48*/         
/*LN-49*/         shares[msg.sender] -= sharesAmount;
/*LN-50*/         totalShares -= sharesAmount;
/*LN-51*/         
/*LN-52*/         IERC20(wantToken).transfer(msg.sender, amount);
/*LN-53*/     }
/*LN-54*/ }
/*LN-55*/ 