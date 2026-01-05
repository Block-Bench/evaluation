/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x6e3d9a, uint256 _0xe5feba) external returns (bool);
/*LN-4*/     function _0x7d6277(
/*LN-5*/         address from,
/*LN-6*/         address _0x6e3d9a,
/*LN-7*/         uint256 _0xe5feba
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0xd80623(address _0x771f54) external view returns (uint256);
/*LN-10*/     function _0x0d961f(address _0xd6cb4d, uint256 _0xe5feba) external returns (bool);
/*LN-11*/ }
/*LN-12*/ enum TokenLockup {
/*LN-13*/     Unlocked,
/*LN-14*/     Locked,
/*LN-15*/     Vesting
/*LN-16*/ }
/*LN-17*/ struct Campaign {
/*LN-18*/     address _0x6ff151;
/*LN-19*/     address _0x0353ce;
/*LN-20*/     uint256 _0xe5feba;
/*LN-21*/     uint256 _0x4f9b02;
/*LN-22*/     TokenLockup _0x477183;
/*LN-23*/     bytes32 _0x8e4527;
/*LN-24*/ }
/*LN-25*/ struct ClaimLockup {
/*LN-26*/     address _0x347a3f;
/*LN-27*/     uint256 _0xd860ea;
/*LN-28*/     uint256 _0x51bedd;
/*LN-29*/     uint256 _0x8e6f03;
/*LN-30*/     uint256 _0x65ce0c;
/*LN-31*/ }
/*LN-32*/ struct Donation {
/*LN-33*/     address _0x347a3f;
/*LN-34*/     uint256 _0xe5feba;
/*LN-35*/     uint256 _0xae3550;
/*LN-36*/     uint256 _0xd860ea;
/*LN-37*/     uint256 _0x51bedd;
/*LN-38*/     uint256 _0x8e6f03;
/*LN-39*/ }
/*LN-40*/ contract TokenClaimCampaigns {
/*LN-41*/     mapping(bytes16 => Campaign) public _0x1045d1;
/*LN-42*/     function _0x390062(
/*LN-43*/         bytes16 _0xac561e,
/*LN-44*/         Campaign memory _0x2ff8d2,
/*LN-45*/         ClaimLockup memory _0x7248ad,
/*LN-46*/         Donation memory _0x0f4194
/*LN-47*/     ) external {
/*LN-48*/         require(_0x1045d1[_0xac561e]._0x6ff151 == address(0), "Campaign exists");
/*LN-49*/         _0x1045d1[_0xac561e] = _0x2ff8d2;
/*LN-50*/         if (_0x0f4194._0xe5feba > 0 && _0x0f4194._0x347a3f != address(0)) {
/*LN-51*/             (bool _0x70dd97, ) = _0x0f4194._0x347a3f.call(
/*LN-52*/                 abi._0x0cce35(
/*LN-53*/                     "createTokenLock(address,uint256,uint256,uint256,uint256,uint256)",
/*LN-54*/                     _0x2ff8d2._0x0353ce,
/*LN-55*/                     _0x0f4194._0xe5feba,
/*LN-56*/                     _0x0f4194._0xd860ea,
/*LN-57*/                     _0x0f4194._0x51bedd,
/*LN-58*/                     _0x0f4194._0xae3550,
/*LN-59*/                     _0x0f4194._0x8e6f03
/*LN-60*/                 )
/*LN-61*/             );
/*LN-62*/             require(_0x70dd97, "Token lock failed");
/*LN-63*/         }
/*LN-64*/     }
/*LN-65*/     function _0x8cd0a4(bytes16 _0x2c833f) external {
/*LN-66*/         require(_0x1045d1[_0x2c833f]._0x6ff151 == msg.sender, "Not manager");
/*LN-67*/         delete _0x1045d1[_0x2c833f];
/*LN-68*/     }
/*LN-69*/ }