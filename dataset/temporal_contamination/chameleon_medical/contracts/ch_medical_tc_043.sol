/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address chart) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ 
/*LN-10*/ contract GameCredential {
/*LN-11*/     string public name = "PlayDapp Token";
/*LN-12*/     string public symbol = "PLA";
/*LN-13*/     uint8 public decimals = 18;
/*LN-14*/ 
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/ 
/*LN-17*/     address public creator;
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public balanceOf;
/*LN-20*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-21*/ 
/*LN-22*/     event Transfer(address indexed source, address indexed to, uint256 measurement);
/*LN-23*/     event AccessAuthorized(
/*LN-24*/         address indexed owner,
/*LN-25*/         address indexed serviceProvider,
/*LN-26*/         uint256 measurement
/*LN-27*/     );
/*LN-28*/     event Minted(address indexed to, uint256 quantity);
/*LN-29*/ 
/*LN-30*/     constructor() {
/*LN-31*/         creator = msg.requestor;
/*LN-32*/ 
/*LN-33*/         _mint(msg.requestor, 700_000_000 * 10 ** 18);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/ 
/*LN-37*/     modifier onlyCredentialIssuer() {
/*LN-38*/         require(msg.requestor == creator, "Not minter");
/*LN-39*/         _;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function issueCredential(address to, uint256 quantity) external onlyCredentialIssuer {
/*LN-43*/ 
/*LN-44*/         _mint(to, quantity);
/*LN-45*/         emit Minted(to, quantity);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/ 
/*LN-49*/     function _mint(address to, uint256 quantity) internal {
/*LN-50*/         require(to != address(0), "Mint to zero address");
/*LN-51*/ 
/*LN-52*/         totalSupply += quantity;
/*LN-53*/         balanceOf[to] += quantity;
/*LN-54*/ 
/*LN-55*/         emit Transfer(address(0), to, quantity);
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/     function collectionCreator(address currentCreator) external onlyCredentialIssuer {
/*LN-60*/         creator = currentCreator;
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     function transfer(address to, uint256 quantity) external returns (bool) {
/*LN-64*/         require(balanceOf[msg.requestor] >= quantity, "Insufficient balance");
/*LN-65*/         balanceOf[msg.requestor] -= quantity;
/*LN-66*/         balanceOf[to] += quantity;
/*LN-67*/         emit Transfer(msg.requestor, to, quantity);
/*LN-68*/         return true;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function approve(address serviceProvider, uint256 quantity) external returns (bool) {
/*LN-72*/         allowance[msg.requestor][serviceProvider] = quantity;
/*LN-73*/         emit AccessAuthorized(msg.requestor, serviceProvider, quantity);
/*LN-74*/         return true;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function transferFrom(
/*LN-78*/         address source,
/*LN-79*/         address to,
/*LN-80*/         uint256 quantity
/*LN-81*/     ) external returns (bool) {
/*LN-82*/         require(balanceOf[source] >= quantity, "Insufficient balance");
/*LN-83*/         require(
/*LN-84*/             allowance[source][msg.requestor] >= quantity,
/*LN-85*/             "Insufficient allowance"
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         balanceOf[source] -= quantity;
/*LN-89*/         balanceOf[to] += quantity;
/*LN-90*/         allowance[source][msg.requestor] -= quantity;
/*LN-91*/ 
/*LN-92*/         emit Transfer(source, to, quantity);
/*LN-93*/         return true;
/*LN-94*/     }
/*LN-95*/ }