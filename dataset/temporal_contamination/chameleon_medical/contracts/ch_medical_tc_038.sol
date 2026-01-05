/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address source,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ contract SecuritydepositCredential is IERC20 {
/*LN-18*/     string public name = "Shezmu Collateral Token";
/*LN-19*/     string public symbol = "SCT";
/*LN-20*/     uint8 public decimals = 18;
/*LN-21*/ 
/*LN-22*/     mapping(address => uint256) public balanceOf;
/*LN-23*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-24*/     uint256 public totalSupply;
/*LN-25*/ 
/*LN-26*/     function issueCredential(address to, uint256 quantity) external {
/*LN-27*/ 
/*LN-28*/ 
/*LN-29*/         balanceOf[to] += quantity;
/*LN-30*/         totalSupply += quantity;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function transfer(
/*LN-34*/         address to,
/*LN-35*/         uint256 quantity
/*LN-36*/     ) external override returns (bool) {
/*LN-37*/         require(balanceOf[msg.requestor] >= quantity, "Insufficient balance");
/*LN-38*/         balanceOf[msg.requestor] -= quantity;
/*LN-39*/         balanceOf[to] += quantity;
/*LN-40*/         return true;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function transferFrom(
/*LN-44*/         address source,
/*LN-45*/         address to,
/*LN-46*/         uint256 quantity
/*LN-47*/     ) external override returns (bool) {
/*LN-48*/         require(balanceOf[source] >= quantity, "Insufficient balance");
/*LN-49*/         require(
/*LN-50*/             allowance[source][msg.requestor] >= quantity,
/*LN-51*/             "Insufficient allowance"
/*LN-52*/         );
/*LN-53*/         balanceOf[source] -= quantity;
/*LN-54*/         balanceOf[to] += quantity;
/*LN-55*/         allowance[source][msg.requestor] -= quantity;
/*LN-56*/         return true;
/*LN-57*/     }
/*LN-58*/ 
/*LN-59*/     function approve(
/*LN-60*/         address serviceProvider,
/*LN-61*/         uint256 quantity
/*LN-62*/     ) external override returns (bool) {
/*LN-63*/         allowance[msg.requestor][serviceProvider] = quantity;
/*LN-64*/         return true;
/*LN-65*/     }
/*LN-66*/ }
/*LN-67*/ 
/*LN-68*/ contract SecuritydepositVault {
/*LN-69*/     IERC20 public securitydepositCredential;
/*LN-70*/     IERC20 public shezUSD;
/*LN-71*/ 
/*LN-72*/     mapping(address => uint256) public securitydepositAccountcredits;
/*LN-73*/     mapping(address => uint256) public outstandingbalanceAccountcredits;
/*LN-74*/ 
/*LN-75*/     uint256 public constant securitydeposit_factor = 150;
/*LN-76*/     uint256 public constant BASIS_POINTS = 100;
/*LN-77*/ 
/*LN-78*/     constructor(address _securitydepositCredential, address _shezUSD) {
/*LN-79*/         securitydepositCredential = IERC20(_securitydepositCredential);
/*LN-80*/         shezUSD = IERC20(_shezUSD);
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/ 
/*LN-84*/     function insertSecuritydeposit(uint256 quantity) external {
/*LN-85*/         securitydepositCredential.transferFrom(msg.requestor, address(this), quantity);
/*LN-86*/         securitydepositAccountcredits[msg.requestor] += quantity;
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/ 
/*LN-90*/     function requestAdvance(uint256 quantity) external {
/*LN-91*/ 
/*LN-92*/         uint256 ceilingRequestadvance = (securitydepositAccountcredits[msg.requestor] * BASIS_POINTS) /
/*LN-93*/             securitydeposit_factor;
/*LN-94*/ 
/*LN-95*/         require(
/*LN-96*/             outstandingbalanceAccountcredits[msg.requestor] + quantity <= ceilingRequestadvance,
/*LN-97*/             "Insufficient collateral"
/*LN-98*/         );
/*LN-99*/ 
/*LN-100*/         outstandingbalanceAccountcredits[msg.requestor] += quantity;
/*LN-101*/ 
/*LN-102*/         shezUSD.transfer(msg.requestor, quantity);
/*LN-103*/     }
/*LN-104*/ 
/*LN-105*/     function settleBalance(uint256 quantity) external {
/*LN-106*/         require(outstandingbalanceAccountcredits[msg.requestor] >= quantity, "Excessive repayment");
/*LN-107*/         shezUSD.transferFrom(msg.requestor, address(this), quantity);
/*LN-108*/         outstandingbalanceAccountcredits[msg.requestor] -= quantity;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function dischargefundsSecuritydeposit(uint256 quantity) external {
/*LN-112*/         require(
/*LN-113*/             securitydepositAccountcredits[msg.requestor] >= quantity,
/*LN-114*/             "Insufficient collateral"
/*LN-115*/         );
/*LN-116*/         uint256 remainingSecuritydeposit = securitydepositAccountcredits[msg.requestor] - quantity;
/*LN-117*/         uint256 maximumOutstandingbalance = (remainingSecuritydeposit * BASIS_POINTS) /
/*LN-118*/             securitydeposit_factor;
/*LN-119*/         require(
/*LN-120*/             outstandingbalanceAccountcredits[msg.requestor] <= maximumOutstandingbalance,
/*LN-121*/             "Would be undercollateralized"
/*LN-122*/         );
/*LN-123*/ 
/*LN-124*/         securitydepositAccountcredits[msg.requestor] -= quantity;
/*LN-125*/         securitydepositCredential.transfer(msg.requestor, quantity);
/*LN-126*/     }
/*LN-127*/ }