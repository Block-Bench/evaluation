/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xe5feba, uint256 _0x65ce0c) external returns (bool);
/*LN-4*/     function _0x477183(
/*LN-5*/         address from,
/*LN-6*/         address _0xe5feba,
/*LN-7*/         uint256 _0x65ce0c
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0xd80623(address _0x0f4194) external view returns (uint256);
/*LN-10*/     function _0x2ff8d2(address _0x0d961f, uint256 _0x65ce0c) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface IPendleMarket {
/*LN-13*/     function _0x8cd0a4() external view returns (address[] memory);
/*LN-14*/     function _0x390062() external returns (uint256[] memory);
/*LN-15*/     function _0x7248ad(address _0x70dd97) external returns (uint256[] memory);
/*LN-16*/ }
/*LN-17*/ contract VeTokenStaking {
/*LN-18*/     mapping(address => mapping(address => uint256)) public _0x347a3f;
/*LN-19*/     mapping(address => uint256) public _0x2c833f;
/*LN-20*/     function _0x771f54(address _0xd6cb4d, uint256 _0x65ce0c) external {
/*LN-21*/         IERC20(_0xd6cb4d)._0x477183(msg.sender, address(this), _0x65ce0c);
/*LN-22*/         _0x347a3f[_0xd6cb4d][msg.sender] += _0x65ce0c;
/*LN-23*/         _0x2c833f[_0xd6cb4d] += _0x65ce0c;
/*LN-24*/     }
/*LN-25*/     function _0x7248ad(address _0xd6cb4d, address _0x70dd97) external {
/*LN-26*/         uint256[] memory _0x6ff151 = IPendleMarket(_0xd6cb4d)._0x7248ad(_0x70dd97);
/*LN-27*/         for (uint256 i = 0; i < _0x6ff151.length; i++) {
/*LN-28*/         }
/*LN-29*/     }
/*LN-30*/     function _0x1045d1(address _0xd6cb4d, uint256 _0x65ce0c) external {
/*LN-31*/         require(
/*LN-32*/             _0x347a3f[_0xd6cb4d][msg.sender] >= _0x65ce0c,
/*LN-33*/             "Insufficient balance"
/*LN-34*/         );
/*LN-35*/         _0x347a3f[_0xd6cb4d][msg.sender] -= _0x65ce0c;
/*LN-36*/         _0x2c833f[_0xd6cb4d] -= _0x65ce0c;
/*LN-37*/         IERC20(_0xd6cb4d).transfer(msg.sender, _0x65ce0c);
/*LN-38*/     }
/*LN-39*/ }
/*LN-40*/ contract YieldMarketRegister {
/*LN-41*/     mapping(address => bool) public _0x0cce35;
/*LN-42*/     function _0x7d6277(address _0xd6cb4d) external {
/*LN-43*/         _0x0cce35[_0xd6cb4d] = true;
/*LN-44*/     }
/*LN-45*/ }