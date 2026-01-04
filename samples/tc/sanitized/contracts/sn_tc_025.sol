/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-7*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract DeflatToken {
/*LN-11*/     mapping(address => uint256) public balanceOf;
/*LN-12*/     uint256 public totalSupply;
/*LN-13*/     uint256 public feePercent = 10; // 10% burn on transfer
/*LN-14*/ 
/*LN-15*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-16*/         uint256 fee = (amount * feePercent) / 100;
/*LN-17*/         uint256 amountAfterFee = amount - fee;
/*LN-18*/ 
/*LN-19*/         balanceOf[msg.sender] -= amount;
/*LN-20*/         balanceOf[to] += amountAfterFee;
/*LN-21*/         totalSupply -= fee; // Burn fee
/*LN-22*/ 
/*LN-23*/         return true;
/*LN-24*/     }
/*LN-25*/ 
/*LN-26*/     function transferFrom(address from, address to, uint256 amount) external returns (bool) {
/*LN-27*/         uint256 fee = (amount * feePercent) / 100;
/*LN-28*/         uint256 amountAfterFee = amount - fee;
/*LN-29*/ 
/*LN-30*/         balanceOf[from] -= amount;
/*LN-31*/         balanceOf[to] += amountAfterFee;
/*LN-32*/         totalSupply -= fee;
/*LN-33*/ 
/*LN-34*/         return true;
/*LN-35*/     }
/*LN-36*/ }
/*LN-37*/ 
/*LN-38*/ contract Vault {
/*LN-39*/     address public token;
/*LN-40*/     mapping(address => uint256) public deposits;
/*LN-41*/ 
/*LN-42*/     constructor(address _token) {
/*LN-43*/         token = _token;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function deposit(uint256 amount) external {
/*LN-47*/ 
/*LN-48*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-49*/ 
/*LN-50*/         deposits[msg.sender] += amount;
/*LN-51*/ 
/*LN-52*/     }
/*LN-53*/ 
/*LN-54*/     function withdraw(uint256 amount) external {
/*LN-55*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-56*/ 
/*LN-57*/         deposits[msg.sender] -= amount;
/*LN-58*/ 
/*LN-59*/         IERC20(token).transfer(msg.sender, amount);
/*LN-60*/     }
/*LN-61*/ }
/*LN-62*/ 