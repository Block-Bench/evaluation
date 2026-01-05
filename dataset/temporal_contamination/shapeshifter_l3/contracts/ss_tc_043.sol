/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xe5feba, uint256 _0x6ff151) external returns (bool);
/*LN-4*/     function _0x347a3f(address _0xd80623) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ contract GameToken {
/*LN-7*/     string public _0x70dd97 = "PlayDapp Token";
/*LN-8*/     string public _0x771f54 = "PLA";
/*LN-9*/     uint8 public _0x2c833f = 18;
/*LN-10*/     uint256 public _0x0cce35;
/*LN-11*/     address public _0x2ff8d2;
/*LN-12*/     mapping(address => uint256) public _0x347a3f;
/*LN-13*/     mapping(address => mapping(address => uint256)) public _0x7248ad;
/*LN-14*/     event Transfer(address indexed from, address indexed _0xe5feba, uint256 value);
/*LN-15*/     event Approval(
/*LN-16*/         address indexed _0x0d961f,
/*LN-17*/         address indexed _0x0f4194,
/*LN-18*/         uint256 value
/*LN-19*/     );
/*LN-20*/     event Minted(address indexed _0xe5feba, uint256 _0x6ff151);
/*LN-21*/     constructor() {
/*LN-22*/         _0x2ff8d2 = msg.sender;
/*LN-23*/         _0x65ce0c(msg.sender, 700_000_000 * 10 ** 18);
/*LN-24*/     }
/*LN-25*/     modifier _0x8cd0a4() {
/*LN-26*/         require(msg.sender == _0x2ff8d2, "Not minter");
/*LN-27*/         _;
/*LN-28*/     }
/*LN-29*/     function _0xd6cb4d(address _0xe5feba, uint256 _0x6ff151) external _0x8cd0a4 {
/*LN-30*/         _0x65ce0c(_0xe5feba, _0x6ff151);
/*LN-31*/         emit Minted(_0xe5feba, _0x6ff151);
/*LN-32*/     }
/*LN-33*/     function _0x65ce0c(address _0xe5feba, uint256 _0x6ff151) internal {
/*LN-34*/         require(_0xe5feba != address(0), "Mint to zero address");
/*LN-35*/         _0x0cce35 += _0x6ff151;
/*LN-36*/         _0x347a3f[_0xe5feba] += _0x6ff151;
/*LN-37*/         emit Transfer(address(0), _0xe5feba, _0x6ff151);
/*LN-38*/     }
/*LN-39*/     function _0x7d6277(address _0x477183) external _0x8cd0a4 {
/*LN-40*/         if (block.timestamp > 0) { _0x2ff8d2 = _0x477183; }
/*LN-41*/     }
/*LN-42*/     function transfer(address _0xe5feba, uint256 _0x6ff151) external returns (bool) {
/*LN-43*/         require(_0x347a3f[msg.sender] >= _0x6ff151, "Insufficient balance");
/*LN-44*/         _0x347a3f[msg.sender] -= _0x6ff151;
/*LN-45*/         _0x347a3f[_0xe5feba] += _0x6ff151;
/*LN-46*/         emit Transfer(msg.sender, _0xe5feba, _0x6ff151);
/*LN-47*/         return true;
/*LN-48*/     }
/*LN-49*/     function _0x1045d1(address _0x0f4194, uint256 _0x6ff151) external returns (bool) {
/*LN-50*/         _0x7248ad[msg.sender][_0x0f4194] = _0x6ff151;
/*LN-51*/         emit Approval(msg.sender, _0x0f4194, _0x6ff151);
/*LN-52*/         return true;
/*LN-53*/     }
/*LN-54*/     function _0x390062(
/*LN-55*/         address from,
/*LN-56*/         address _0xe5feba,
/*LN-57*/         uint256 _0x6ff151
/*LN-58*/     ) external returns (bool) {
/*LN-59*/         require(_0x347a3f[from] >= _0x6ff151, "Insufficient balance");
/*LN-60*/         require(
/*LN-61*/             _0x7248ad[from][msg.sender] >= _0x6ff151,
/*LN-62*/             "Insufficient allowance"
/*LN-63*/         );
/*LN-64*/         _0x347a3f[from] -= _0x6ff151;
/*LN-65*/         _0x347a3f[_0xe5feba] += _0x6ff151;
/*LN-66*/         _0x7248ad[from][msg.sender] -= _0x6ff151;
/*LN-67*/         emit Transfer(from, _0xe5feba, _0x6ff151);
/*LN-68*/         return true;
/*LN-69*/     }
/*LN-70*/ }