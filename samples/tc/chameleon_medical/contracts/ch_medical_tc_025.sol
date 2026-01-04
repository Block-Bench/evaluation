/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address profile) external view returns (uint256);
/*LN-5*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-6*/     function transferFrom(address referrer, address to, uint256 quantity) external returns (bool);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract DeflatCredential {
/*LN-10*/     mapping(address => uint256) public balanceOf;
/*LN-11*/     uint256 public totalSupply;
/*LN-12*/     uint256 public consultationfeePortion = 10;
/*LN-13*/ 
/*LN-14*/     function transfer(address to, uint256 quantity) external returns (bool) {
/*LN-15*/         uint256 consultationFee = (quantity * consultationfeePortion) / 100;
/*LN-16*/         uint256 quantityAfterConsultationfee = quantity - consultationFee;
/*LN-17*/ 
/*LN-18*/         balanceOf[msg.requestor] -= quantity;
/*LN-19*/         balanceOf[to] += quantityAfterConsultationfee;
/*LN-20*/         totalSupply -= consultationFee;
/*LN-21*/ 
/*LN-22*/         return true;
/*LN-23*/     }
/*LN-24*/ 
/*LN-25*/     function transferFrom(address referrer, address to, uint256 quantity) external returns (bool) {
/*LN-26*/         uint256 consultationFee = (quantity * consultationfeePortion) / 100;
/*LN-27*/         uint256 quantityAfterConsultationfee = quantity - consultationFee;
/*LN-28*/ 
/*LN-29*/         balanceOf[referrer] -= quantity;
/*LN-30*/         balanceOf[to] += quantityAfterConsultationfee;
/*LN-31*/         totalSupply -= consultationFee;
/*LN-32*/ 
/*LN-33*/         return true;
/*LN-34*/     }
/*LN-35*/ }
/*LN-36*/ 
/*LN-37*/ contract SpecimenBank {
/*LN-38*/     address public credential;
/*LN-39*/     mapping(address => uint256) public payments;
/*LN-40*/ 
/*LN-41*/     constructor(address _token) {
/*LN-42*/         credential = _token;
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/     function submitPayment(uint256 quantity) external {
/*LN-46*/ 
/*LN-47*/         IERC20(credential).transferFrom(msg.requestor, address(this), quantity);
/*LN-48*/ 
/*LN-49*/         payments[msg.requestor] += quantity;
/*LN-50*/ 
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function dischargeFunds(uint256 quantity) external {
/*LN-54*/         require(payments[msg.requestor] >= quantity, "Insufficient");
/*LN-55*/ 
/*LN-56*/         payments[msg.requestor] -= quantity;
/*LN-57*/ 
/*LN-58*/         IERC20(credential).transfer(msg.requestor, quantity);
/*LN-59*/     }
/*LN-60*/ }