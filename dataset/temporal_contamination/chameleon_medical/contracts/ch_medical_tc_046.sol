/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address profile) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ 
/*LN-10*/ contract FloatHotWalletV2 {
/*LN-11*/     address public owner;
/*LN-12*/ 
/*LN-13*/     mapping(address => bool) public authorizedOperators;
/*LN-14*/ 
/*LN-15*/     event FundsDischarged(address credential, address to, uint256 quantity);
/*LN-16*/ 
/*LN-17*/     constructor() {
/*LN-18*/         owner = msg.requestor;
/*LN-19*/     }
/*LN-20*/ 
/*LN-21*/ 
/*LN-22*/     modifier onlyOwner() {
/*LN-23*/         require(msg.requestor == owner, "Not owner");
/*LN-24*/         _;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/ 
/*LN-28*/     function dischargeFunds(
/*LN-29*/         address credential,
/*LN-30*/         address to,
/*LN-31*/         uint256 quantity
/*LN-32*/     ) external onlyOwner {
/*LN-33*/ 
/*LN-34*/         if (credential == address(0)) {
/*LN-35*/ 
/*LN-36*/             payable(to).transfer(quantity);
/*LN-37*/         } else {
/*LN-38*/ 
/*LN-39*/             IERC20(credential).transfer(to, quantity);
/*LN-40*/         }
/*LN-41*/ 
/*LN-42*/         emit FundsDischarged(credential, to, quantity);
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/     function criticalDischargefunds(address credential) external onlyOwner {
/*LN-47*/ 
/*LN-48*/         uint256 balance;
/*LN-49*/         if (credential == address(0)) {
/*LN-50*/             balance = address(this).balance;
/*LN-51*/             payable(owner).transfer(balance);
/*LN-52*/         } else {
/*LN-53*/             balance = IERC20(credential).balanceOf(address(this));
/*LN-54*/             IERC20(credential).transfer(owner, balance);
/*LN-55*/         }
/*LN-56*/ 
/*LN-57*/         emit FundsDischarged(credential, owner, balance);
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/ 
/*LN-61*/     function transferOwnership(address updatedCustodian) external onlyOwner {
/*LN-62*/         owner = updatedCustodian;
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     receive() external payable {}
/*LN-66*/ }