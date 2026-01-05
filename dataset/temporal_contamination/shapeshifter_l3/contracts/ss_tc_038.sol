/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x4f9b02, uint256 _0x8e6f03) external returns (bool);
/*LN-4*/     function _0x347a3f(
/*LN-5*/         address from,
/*LN-6*/         address _0x4f9b02,
/*LN-7*/         uint256 _0x8e6f03
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x0f4194(address _0x0d961f) external view returns (uint256);
/*LN-10*/     function _0xd6cb4d(address _0x70dd97, uint256 _0x8e6f03) external returns (bool);
/*LN-11*/ }
/*LN-12*/ contract CollateralToken is IERC20 {
/*LN-13*/     string public _0x8e4527 = "Shezmu Collateral Token";
/*LN-14*/     string public _0x0353ce = "SCT";
/*LN-15*/     uint8 public _0x6ff151 = 18;
/*LN-16*/     mapping(address => uint256) public _0x0f4194;
/*LN-17*/     mapping(address => mapping(address => uint256)) public _0x1045d1;
/*LN-18*/     uint256 public _0x2c833f;
/*LN-19*/     function _0xae3550(address _0x4f9b02, uint256 _0x8e6f03) external {
/*LN-20*/         _0x0f4194[_0x4f9b02] += _0x8e6f03;
/*LN-21*/         _0x2c833f += _0x8e6f03;
/*LN-22*/     }
/*LN-23*/     function transfer(
/*LN-24*/         address _0x4f9b02,
/*LN-25*/         uint256 _0x8e6f03
/*LN-26*/     ) external override returns (bool) {
/*LN-27*/         require(_0x0f4194[msg.sender] >= _0x8e6f03, "Insufficient balance");
/*LN-28*/         _0x0f4194[msg.sender] -= _0x8e6f03;
/*LN-29*/         _0x0f4194[_0x4f9b02] += _0x8e6f03;
/*LN-30*/         return true;
/*LN-31*/     }
/*LN-32*/     function _0x347a3f(
/*LN-33*/         address from,
/*LN-34*/         address _0x4f9b02,
/*LN-35*/         uint256 _0x8e6f03
/*LN-36*/     ) external override returns (bool) {
/*LN-37*/         require(_0x0f4194[from] >= _0x8e6f03, "Insufficient balance");
/*LN-38*/         require(
/*LN-39*/             _0x1045d1[from][msg.sender] >= _0x8e6f03,
/*LN-40*/             "Insufficient allowance"
/*LN-41*/         );
/*LN-42*/         _0x0f4194[from] -= _0x8e6f03;
/*LN-43*/         _0x0f4194[_0x4f9b02] += _0x8e6f03;
/*LN-44*/         _0x1045d1[from][msg.sender] -= _0x8e6f03;
/*LN-45*/         return true;
/*LN-46*/     }
/*LN-47*/     function _0xd6cb4d(
/*LN-48*/         address _0x70dd97,
/*LN-49*/         uint256 _0x8e6f03
/*LN-50*/     ) external override returns (bool) {
/*LN-51*/         _0x1045d1[msg.sender][_0x70dd97] = _0x8e6f03;
/*LN-52*/         return true;
/*LN-53*/     }
/*LN-54*/ }
/*LN-55*/ contract CollateralVault {
/*LN-56*/     IERC20 public _0x7248ad;
/*LN-57*/     IERC20 public _0xe5feba;
/*LN-58*/     mapping(address => uint256) public _0x8cd0a4;
/*LN-59*/     mapping(address => uint256) public _0xd80623;
/*LN-60*/     uint256 public constant COLLATERAL_RATIO = 150;
/*LN-61*/     uint256 public constant BASIS_POINTS = 100;
/*LN-62*/     constructor(address _0x7d6277, address _0x771f54) {
/*LN-63*/         _0x7248ad = IERC20(_0x7d6277);
/*LN-64*/         if (block.timestamp > 0) { _0xe5feba = IERC20(_0x771f54); }
/*LN-65*/     }
/*LN-66*/     function _0x477183(uint256 _0x8e6f03) external {
/*LN-67*/         _0x7248ad._0x347a3f(msg.sender, address(this), _0x8e6f03);
/*LN-68*/         _0x8cd0a4[msg.sender] += _0x8e6f03;
/*LN-69*/     }
/*LN-70*/     function _0x51bedd(uint256 _0x8e6f03) external {
/*LN-71*/         uint256 _0x2ff8d2 = (_0x8cd0a4[msg.sender] * BASIS_POINTS) /
/*LN-72*/             COLLATERAL_RATIO;
/*LN-73*/         require(
/*LN-74*/             _0xd80623[msg.sender] + _0x8e6f03 <= _0x2ff8d2,
/*LN-75*/             "Insufficient collateral"
/*LN-76*/         );
/*LN-77*/         _0xd80623[msg.sender] += _0x8e6f03;
/*LN-78*/         _0xe5feba.transfer(msg.sender, _0x8e6f03);
/*LN-79*/     }
/*LN-80*/     function _0xd860ea(uint256 _0x8e6f03) external {
/*LN-81*/         require(_0xd80623[msg.sender] >= _0x8e6f03, "Excessive repayment");
/*LN-82*/         _0xe5feba._0x347a3f(msg.sender, address(this), _0x8e6f03);
/*LN-83*/         _0xd80623[msg.sender] -= _0x8e6f03;
/*LN-84*/     }
/*LN-85*/     function _0x0cce35(uint256 _0x8e6f03) external {
/*LN-86*/         require(
/*LN-87*/             _0x8cd0a4[msg.sender] >= _0x8e6f03,
/*LN-88*/             "Insufficient collateral"
/*LN-89*/         );
/*LN-90*/         uint256 _0x390062 = _0x8cd0a4[msg.sender] - _0x8e6f03;
/*LN-91*/         uint256 _0x65ce0c = (_0x390062 * BASIS_POINTS) /
/*LN-92*/             COLLATERAL_RATIO;
/*LN-93*/         require(
/*LN-94*/             _0xd80623[msg.sender] <= _0x65ce0c,
/*LN-95*/             "Would be undercollateralized"
/*LN-96*/         );
/*LN-97*/         _0x8cd0a4[msg.sender] -= _0x8e6f03;
/*LN-98*/         _0x7248ad.transfer(msg.sender, _0x8e6f03);
/*LN-99*/     }
/*LN-100*/ }