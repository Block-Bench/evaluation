/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address account) external view returns (uint256);
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract DeflatToken {
/*LN-10*/     mapping(address => uint256) public balanceOf;
/*LN-11*/     uint256 public totalSupply;
/*LN-12*/     uint256 public feePercent = 10;
/*LN-13*/ 
/*LN-14*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-15*/         uint256 fee = (amount * feePercent) / 100;
/*LN-16*/         uint256 amountAfterFee = amount - fee;
/*LN-17*/ 
/*LN-18*/         balanceOf[msg.sender] -= amount;
/*LN-19*/         balanceOf[to] += amountAfterFee;
/*LN-20*/         totalSupply -= fee;
/*LN-21*/ 
/*LN-22*/         return true;
/*LN-23*/     }
/*LN-24*/ 
/*LN-25*/     function transferFrom(address from, address to, uint256 amount) external returns (bool) {
/*LN-26*/         uint256 fee = (amount * feePercent) / 100;
/*LN-27*/         uint256 amountAfterFee = amount - fee;
/*LN-28*/ 
/*LN-29*/         balanceOf[from] -= amount;
/*LN-30*/         balanceOf[to] += amountAfterFee;
/*LN-31*/         totalSupply -= fee;
/*LN-32*/ 
/*LN-33*/         return true;
/*LN-34*/     }
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract Vault {
/*LN-38*/     address public token;
/*LN-39*/     mapping(address => uint256) public deposits;
/*LN-40*/ 
/*LN-41*/     constructor(address _token) {
/*LN-42*/         token = _token;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     function deposit(uint256 amount) external {
/*LN-46*/ 
/*LN-47*/         IERC20(token).transferFrom(msg.sender, address(this), amount);
/*LN-48*/ 
/*LN-49*/         deposits[msg.sender] += amount;
/*LN-50*/ 
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function withdraw(uint256 amount) external {
/*LN-54*/         require(deposits[msg.sender] >= amount, "Insufficient");
/*LN-55*/ 
/*LN-56*/         deposits[msg.sender] -= amount;
/*LN-57*/ 
/*LN-58*/         IERC20(token).transfer(msg.sender, amount);
/*LN-59*/     }
/*LN-60*/ }