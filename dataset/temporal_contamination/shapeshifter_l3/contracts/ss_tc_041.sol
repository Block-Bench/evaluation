/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x8e4527, uint256 _0xe5feba) external returns (bool);
/*LN-4*/     function _0x477183(
/*LN-5*/         address from,
/*LN-6*/         address _0x8e4527,
/*LN-7*/         uint256 _0xe5feba
/*LN-8*/     ) external returns (bool);
/*LN-9*/     function _0x2ff8d2(address _0x0d961f) external view returns (uint256);
/*LN-10*/     function _0x65ce0c(address _0x70dd97, uint256 _0xe5feba) external returns (bool);
/*LN-11*/ }
/*LN-12*/ interface ISmartLoan {
/*LN-13*/     function _0x8cd0a4(
/*LN-14*/         bytes32 _0xd80623,
/*LN-15*/         bytes32 _0x771f54,
/*LN-16*/         uint256 _0x7248ad,
/*LN-17*/         uint256 _0x7d6277,
/*LN-18*/         bytes4 selector,
/*LN-19*/         bytes memory data
/*LN-20*/     ) external;
/*LN-21*/     function _0x347a3f(address _0xd860ea, uint256[] calldata _0xae3550) external;
/*LN-22*/ }
/*LN-23*/ contract SmartLoansFactory {
/*LN-24*/     address public _0x8e6f03;
/*LN-25*/     constructor() {
/*LN-26*/         _0x8e6f03 = msg.sender;
/*LN-27*/     }
/*LN-28*/     function _0x1045d1() external returns (address) {
/*LN-29*/         SmartLoan _0x51bedd = new SmartLoan();
/*LN-30*/         return address(_0x51bedd);
/*LN-31*/     }
/*LN-32*/     function _0x2c833f(
/*LN-33*/         address _0x0f4194,
/*LN-34*/         address _0x0cce35
/*LN-35*/     ) external {
/*LN-36*/         require(msg.sender == _0x8e6f03, "Not admin");
/*LN-37*/     }
/*LN-38*/ }
/*LN-39*/ contract SmartLoan is ISmartLoan {
/*LN-40*/     mapping(bytes32 => uint256) public _0x6ff151;
/*LN-41*/     mapping(bytes32 => uint256) public _0x0353ce;
/*LN-42*/     function _0x8cd0a4(
/*LN-43*/         bytes32 _0xd80623,
/*LN-44*/         bytes32 _0x771f54,
/*LN-45*/         uint256 _0x7248ad,
/*LN-46*/         uint256 _0x7d6277,
/*LN-47*/         bytes4 selector,
/*LN-48*/         bytes memory data
/*LN-49*/     ) external override {
/*LN-50*/     }
/*LN-51*/     function _0x347a3f(
/*LN-52*/         address _0xd860ea,
/*LN-53*/         uint256[] calldata _0xae3550
/*LN-54*/     ) external override {
/*LN-55*/         (bool _0xd6cb4d, ) = _0xd860ea.call(
/*LN-56*/             abi._0x390062("claimRewards(address)", msg.sender)
/*LN-57*/         );
/*LN-58*/     }
/*LN-59*/ }