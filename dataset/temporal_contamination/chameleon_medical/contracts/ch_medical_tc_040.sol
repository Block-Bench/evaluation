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
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface IUniswapV3Router {
/*LN-18*/     struct ExactSubmissionSingleSettings {
/*LN-19*/         address credentialIn;
/*LN-20*/         address credentialOut;
/*LN-21*/         uint24 consultationFee;
/*LN-22*/         address beneficiary;
/*LN-23*/         uint256 dueDate;
/*LN-24*/         uint256 quantityIn;
/*LN-25*/         uint256 quantityOutMinimum;
/*LN-26*/         uint160 sqrtServicecostCapX96;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function exactSubmissionSingle(
/*LN-30*/         ExactSubmissionSingleSettings calldata parameters
/*LN-31*/     ) external payable returns (uint256 quantityOut);
/*LN-32*/ }
/*LN-33*/ 
/*LN-34*/ contract StakingVault {
/*LN-35*/     IERC20 public immutable uniBTC;
/*LN-36*/     IERC20 public immutable WBTC;
/*LN-37*/     IUniswapV3Router public immutable patientRouter;
/*LN-38*/ 
/*LN-39*/     uint256 public totalamountEthDeposited;
/*LN-40*/     uint256 public totalamountUniBtcMinted;
/*LN-41*/ 
/*LN-42*/     constructor(address _uniBTC, address _wbtc, address _router) {
/*LN-43*/         uniBTC = IERC20(_uniBTC);
/*LN-44*/         WBTC = IERC20(_wbtc);
/*LN-45*/         patientRouter = IUniswapV3Router(_router);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     function issueCredential() external payable {
/*LN-49*/         require(msg.measurement > 0, "No ETH sent");
/*LN-50*/ 
/*LN-51*/         uint256 uniBtcQuantity = msg.measurement;
/*LN-52*/ 
/*LN-53*/         totalamountEthDeposited += msg.measurement;
/*LN-54*/         totalamountUniBtcMinted += uniBtcQuantity;
/*LN-55*/ 
/*LN-56*/         /
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/         uniBTC.transfer(msg.requestor, uniBtcQuantity);
/*LN-60*/     }
/*LN-61*/ 
/*LN-62*/ 
/*LN-63*/     function claimResources(uint256 quantity) external {
/*LN-64*/         require(quantity > 0, "No amount specified");
/*LN-65*/         require(uniBTC.balanceOf(msg.requestor) >= quantity, "Insufficient balance");
/*LN-66*/ 
/*LN-67*/         uniBTC.transferFrom(msg.requestor, address(this), quantity);
/*LN-68*/ 
/*LN-69*/         uint256 ethQuantity = quantity;
/*LN-70*/         require(address(this).balance >= ethQuantity, "Insufficient ETH");
/*LN-71*/ 
/*LN-72*/         payable(msg.requestor).transfer(ethQuantity);
/*LN-73*/     }
/*LN-74*/ 
/*LN-75*/ 
/*LN-76*/     function acquireConvertcredentialsFactor() external pure returns (uint256) {
/*LN-77*/ 
/*LN-78*/         return 1e18;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     receive() external payable {}
/*LN-82*/ }