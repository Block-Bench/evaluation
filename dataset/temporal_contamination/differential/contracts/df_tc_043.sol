/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract PlayDappToken {
/*LN-10*/     string public name = "PlayDapp Token";
/*LN-11*/     string public symbol = "PLA";
/*LN-12*/     uint8 public decimals = 18;
/*LN-13*/ 
/*LN-14*/     uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
/*LN-15*/     uint256 public totalSupply;
/*LN-16*/ 
/*LN-17*/     address public minter;
/*LN-18*/     mapping(address => bool) public authorizedMinters;
/*LN-19*/     uint256 public constant MIN_SIGNERS = 2;
/*LN-20*/     address[] public minters;
/*LN-21*/ 
/*LN-22*/     mapping(address => uint256) public balanceOf;
/*LN-23*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-24*/ 
/*LN-25*/     event Transfer(address indexed from, address indexed to, uint256 value);
/*LN-26*/     event Approval(
/*LN-27*/         address indexed owner,
/*LN-28*/         address indexed spender,
/*LN-29*/         uint256 value
/*LN-30*/     );
/*LN-31*/     event Minted(address indexed to, uint256 amount);
/*LN-32*/ 
/*LN-33*/     constructor(address[] memory _minters) {
/*LN-34*/         require(_minters.length >= MIN_SIGNERS, "Insufficient minters");
/*LN-35*/         minters = _minters;
/*LN-36*/         minter = msg.sender;
/*LN-37*/         // Initialize authorized minters
/*LN-38*/         for (uint256 i = 0; i < _minters.length; i++) {
/*LN-39*/             authorizedMinters[_minters[i]] = true;
/*LN-40*/         }
/*LN-41*/         _mint(msg.sender, 700_000_000 * 10 ** 18);
/*LN-42*/     }
/*LN-43*/ 
/*LN-44*/     modifier onlyMinter() {
/*LN-45*/         require(authorizedMinters[msg.sender], "Not minter");
/*LN-46*/         _;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     function mint(address to, uint256 amount) external onlyMinter {
/*LN-50*/         require(totalSupply + amount <= MAX_SUPPLY, "Supply cap exceeded");
/*LN-51*/         _mint(to, amount);
/*LN-52*/         emit Minted(to, amount);
/*LN-53*/     }
/*LN-54*/ 
/*LN-55*/     function _mint(address to, uint256 amount) internal {
/*LN-56*/         require(to != address(0), "Mint to zero address");
/*LN-57*/         require(totalSupply + amount <= MAX_SUPPLY, "Supply cap exceeded");
/*LN-58*/ 
/*LN-59*/         totalSupply += amount;
/*LN-60*/         balanceOf[to] += amount;
/*LN-61*/ 
/*LN-62*/         emit Transfer(address(0), to, amount);
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function setMinter(address newMinter) external onlyMinter {
/*LN-66*/         authorizedMinters[newMinter] = true;
/*LN-67*/     }
/*LN-68*/ 
/*LN-69*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-70*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-71*/         balanceOf[msg.sender] -= amount;
/*LN-72*/         balanceOf[to] += amount;
/*LN-73*/         emit Transfer(msg.sender, to, amount);
/*LN-74*/         return true;
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function approve(address spender, uint256 amount) external returns (bool) {
/*LN-78*/         allowance[msg.sender][spender] = amount;
/*LN-79*/         emit Approval(msg.sender, spender, amount);
/*LN-80*/         return true;
/*LN-81*/     }
/*LN-82*/ 
/*LN-83*/     function transferFrom(
/*LN-84*/         address from,
/*LN-85*/         address to,
/*LN-86*/         uint256 amount
/*LN-87*/     ) external returns (bool) {
/*LN-88*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-89*/         require(
/*LN-90*/             allowance[from][msg.sender] >= amount,
/*LN-91*/             "Insufficient allowance"
/*LN-92*/         );
/*LN-93*/ 
/*LN-94*/         balanceOf[from] -= amount;
/*LN-95*/         balanceOf[to] += amount;
/*LN-96*/         allowance[from][msg.sender] -= amount;
/*LN-97*/ 
/*LN-98*/         emit Transfer(from, to, amount);
/*LN-99*/         return true;
/*LN-100*/     }
/*LN-101*/ }
/*LN-102*/ 