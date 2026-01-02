/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ 
/*LN-10*/ contract GameToken {
/*LN-11*/     string public name = "PlayDapp Token";
/*LN-12*/     string public symbol = "PLA";
/*LN-13*/     uint8 public decimals = 18;
/*LN-14*/ 
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/ 
/*LN-17*/     address public minter;
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public balanceOf;
/*LN-20*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-21*/ 
/*LN-22*/     event Transfer(address indexed from, address indexed to, uint256 value);
/*LN-23*/     event Approval(
/*LN-24*/         address indexed owner,
/*LN-25*/         address indexed spender,
/*LN-26*/         uint256 value
/*LN-27*/     );
/*LN-28*/     event Minted(address indexed to, uint256 amount);
/*LN-29*/ 
/*LN-30*/     constructor() {
/*LN-31*/         minter = msg.sender;
/*LN-32*/ 
/*LN-33*/         _mint(msg.sender, 700_000_000 * 10 ** 18);
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/ 
/*LN-37*/     modifier onlyMinter() {
/*LN-38*/         require(msg.sender == minter, "Not minter");
/*LN-39*/         _;
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function mint(address to, uint256 amount) external onlyMinter {
/*LN-43*/ 
/*LN-44*/         _mint(to, amount);
/*LN-45*/         emit Minted(to, amount);
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/ 
/*LN-49*/     function _mint(address to, uint256 amount) internal {
/*LN-50*/         require(to != address(0), "Mint to zero address");
/*LN-51*/ 
/*LN-52*/         totalSupply += amount;
/*LN-53*/         balanceOf[to] += amount;
/*LN-54*/ 
/*LN-55*/         emit Transfer(address(0), to, amount);
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/ 
/*LN-59*/     function setMinter(address newMinter) external onlyMinter {
/*LN-60*/         minter = newMinter;
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-64*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-65*/         balanceOf[msg.sender] -= amount;
/*LN-66*/         balanceOf[to] += amount;
/*LN-67*/         emit Transfer(msg.sender, to, amount);
/*LN-68*/         return true;
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function approve(address spender, uint256 amount) external returns (bool) {
/*LN-72*/         allowance[msg.sender][spender] = amount;
/*LN-73*/         emit Approval(msg.sender, spender, amount);
/*LN-74*/         return true;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function transferFrom(
/*LN-78*/         address from,
/*LN-79*/         address to,
/*LN-80*/         uint256 amount
/*LN-81*/     ) external returns (bool) {
/*LN-82*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-83*/         require(
/*LN-84*/             allowance[from][msg.sender] >= amount,
/*LN-85*/             "Insufficient allowance"
/*LN-86*/         );
/*LN-87*/ 
/*LN-88*/         balanceOf[from] -= amount;
/*LN-89*/         balanceOf[to] += amount;
/*LN-90*/         allowance[from][msg.sender] -= amount;
/*LN-91*/ 
/*LN-92*/         emit Transfer(from, to, amount);
/*LN-93*/         return true;
/*LN-94*/     }
/*LN-95*/ }