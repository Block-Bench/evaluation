/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IComptroller {
/*LN-3*/     function _0x2c833f(
/*LN-4*/         address[] memory _0x70dd97
/*LN-5*/     ) external returns (uint256[] memory);
/*LN-6*/     function _0x1045d1(address _0x51bedd) external returns (uint256);
/*LN-7*/     function _0x0cce35(
/*LN-8*/         address _0xd6cb4d
/*LN-9*/     ) external view returns (uint256, uint256, uint256);
/*LN-10*/ }
/*LN-11*/ contract LendingHub {
/*LN-12*/     IComptroller public _0xd80623;
/*LN-13*/     mapping(address => uint256) public _0x0d961f;
/*LN-14*/     mapping(address => uint256) public _0x6ff151;
/*LN-15*/     mapping(address => bool) public _0x771f54;
/*LN-16*/     uint256 public _0x477183;
/*LN-17*/     uint256 public _0x7248ad;
/*LN-18*/     uint256 public constant COLLATERAL_FACTOR = 150;
/*LN-19*/     constructor(address _0x347a3f) {
/*LN-20*/         _0xd80623 = IComptroller(_0x347a3f);
/*LN-21*/     }
/*LN-22*/     function _0x390062() external payable {
/*LN-23*/         _0x0d961f[msg.sender] += msg.value;
/*LN-24*/         _0x477183 += msg.value;
/*LN-25*/         _0x771f54[msg.sender] = true;
/*LN-26*/     }
/*LN-27*/     function _0x2ff8d2(
/*LN-28*/         address _0xd6cb4d,
/*LN-29*/         uint256 _0x8cd0a4
/*LN-30*/     ) public view returns (bool) {
/*LN-31*/         uint256 _0x0f4194 = _0x6ff151[_0xd6cb4d] + _0x8cd0a4;
/*LN-32*/         if (_0x0f4194 == 0) return true;
/*LN-33*/         if (!_0x771f54[_0xd6cb4d]) return false;
/*LN-34*/         uint256 _0x7d6277 = _0x0d961f[_0xd6cb4d];
/*LN-35*/         return _0x7d6277 >= (_0x0f4194 * COLLATERAL_FACTOR) / 100;
/*LN-36*/     }
/*LN-37*/     function _0x0353ce(uint256 _0x8e6f03) external {
/*LN-38*/         require(_0x8e6f03 > 0, "Invalid amount");
/*LN-39*/         require(address(this).balance >= _0x8e6f03, "Insufficient funds");
/*LN-40*/         require(_0x2ff8d2(msg.sender, _0x8e6f03), "Insufficient collateral");
/*LN-41*/         _0x6ff151[msg.sender] += _0x8e6f03;
/*LN-42*/         _0x7248ad += _0x8e6f03;
/*LN-43*/         (bool _0xe5feba, ) = payable(msg.sender).call{value: _0x8e6f03}("");
/*LN-44*/         require(_0xe5feba, "Transfer failed");
/*LN-45*/         require(_0x2ff8d2(msg.sender, 0), "Health check failed");
/*LN-46*/     }
/*LN-47*/     function _0x1045d1() external {
/*LN-48*/         require(_0x6ff151[msg.sender] == 0, "Outstanding debt");
/*LN-49*/         _0x771f54[msg.sender] = false;
/*LN-50*/     }
/*LN-51*/     function _0x65ce0c(uint256 _0x8e6f03) external {
/*LN-52*/         require(_0x0d961f[msg.sender] >= _0x8e6f03, "Insufficient deposits");
/*LN-53*/         require(!_0x771f54[msg.sender], "Exit market first");
/*LN-54*/         _0x0d961f[msg.sender] -= _0x8e6f03;
/*LN-55*/         _0x477183 -= _0x8e6f03;
/*LN-56*/         payable(msg.sender).transfer(_0x8e6f03);
/*LN-57*/     }
/*LN-58*/     receive() external payable {}
/*LN-59*/ }