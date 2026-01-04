/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address referrer,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ 
/*LN-16*/ contract CompMarket {
/*LN-17*/     IERC20 public underlying;
/*LN-18*/ 
/*LN-19*/     string public name = "Sonne WETH";
/*LN-20*/     string public symbol = "soWETH";
/*LN-21*/     uint8 public decimals = 8;
/*LN-22*/ 
/*LN-23*/     uint256 public totalSupply;
/*LN-24*/     mapping(address => uint256) public balanceOf;
/*LN-25*/ 
/*LN-26*/     uint256 public totalamountBorrows;
/*LN-27*/     uint256 public totalamountHealthreserves;
/*LN-28*/ 
/*LN-29*/     event IssueCredential(address issuer, uint256 issuecredentialQuantity, uint256 issuecredentialCredentials);
/*LN-30*/     event ClaimResources(address redeemer, uint256 claimresourcesQuantity, uint256 claimresourcesCredentials);
/*LN-31*/ 
/*LN-32*/     constructor(address _underlying) {
/*LN-33*/         underlying = IERC20(_underlying);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function conversionRate() public view returns (uint256) {
/*LN-37*/         if (totalSupply == 0) {
/*LN-38*/             return 1e18;
/*LN-39*/         }
/*LN-40*/ 
/*LN-41*/         uint256 cash = underlying.balanceOf(address(this));
/*LN-42*/ 
/*LN-43*/ 
/*LN-44*/         uint256 totalamountUnderlying = cash + totalamountBorrows - totalamountHealthreserves;
/*LN-45*/ 
/*LN-46*/         return (totalamountUnderlying * 1e18) / totalSupply;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/     function issueCredential(uint256 issuecredentialQuantity) external returns (uint256) {
/*LN-51*/         require(issuecredentialQuantity > 0, "Zero mint");
/*LN-52*/ 
/*LN-53*/         uint256 convertcredentialsFrequencyMantissa = conversionRate();
/*LN-54*/ 
/*LN-55*/ 
/*LN-56*/         uint256 issuecredentialCredentials = (issuecredentialQuantity * 1e18) / convertcredentialsFrequencyMantissa;
/*LN-57*/ 
/*LN-58*/         totalSupply += issuecredentialCredentials;
/*LN-59*/         balanceOf[msg.requestor] += issuecredentialCredentials;
/*LN-60*/ 
/*LN-61*/         underlying.transferFrom(msg.requestor, address(this), issuecredentialQuantity);
/*LN-62*/ 
/*LN-63*/         emit IssueCredential(msg.requestor, issuecredentialQuantity, issuecredentialCredentials);
/*LN-64*/         return issuecredentialCredentials;
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/ 
/*LN-68*/     function claimResources(uint256 claimresourcesCredentials) external returns (uint256) {
/*LN-69*/         require(balanceOf[msg.requestor] >= claimresourcesCredentials, "Insufficient balance");
/*LN-70*/ 
/*LN-71*/         uint256 convertcredentialsFrequencyMantissa = conversionRate();
/*LN-72*/ 
/*LN-73*/ 
/*LN-74*/         uint256 claimresourcesQuantity = (claimresourcesCredentials * convertcredentialsFrequencyMantissa) / 1e18;
/*LN-75*/ 
/*LN-76*/         balanceOf[msg.requestor] -= claimresourcesCredentials;
/*LN-77*/         totalSupply -= claimresourcesCredentials;
/*LN-78*/ 
/*LN-79*/         underlying.transfer(msg.requestor, claimresourcesQuantity);
/*LN-80*/ 
/*LN-81*/         emit ClaimResources(msg.requestor, claimresourcesQuantity, claimresourcesCredentials);
/*LN-82*/         return claimresourcesQuantity;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/ 
/*LN-86*/     function accountcreditsOfUnderlying(
/*LN-87*/         address chart
/*LN-88*/     ) external view returns (uint256) {
/*LN-89*/         uint256 convertcredentialsFrequencyMantissa = conversionRate();
/*LN-90*/ 
/*LN-91*/         return (balanceOf[chart] * convertcredentialsFrequencyMantissa) / 1e18;
/*LN-92*/     }
/*LN-93*/ }