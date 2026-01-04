/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0xe5feba, uint256 _0x771f54) external returns (bool);
/*LN-4*/     function _0x2c833f(address _0x6ff151) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ contract CrossBridge {
/*LN-7*/     mapping(bytes32 => bool) public _0x390062;
/*LN-8*/     uint256 public constant REQUIRED_SIGNATURES = 5;
/*LN-9*/     uint256 public constant TOTAL_VALIDATORS = 7;
/*LN-10*/     mapping(address => bool) public _0x7248ad;
/*LN-11*/     address[] public _0x0cce35;
/*LN-12*/     event WithdrawalProcessed(
/*LN-13*/         bytes32 _0x0d961f,
/*LN-14*/         address _0xd6cb4d,
/*LN-15*/         address _0x347a3f,
/*LN-16*/         uint256 _0x771f54
/*LN-17*/     );
/*LN-18*/     constructor() {
/*LN-19*/         _0x0cce35 = new address[](TOTAL_VALIDATORS);
/*LN-20*/     }
/*LN-21*/     function _0x2ff8d2(
/*LN-22*/         address _0x7d6277,
/*LN-23*/         string memory _0xd80623,
/*LN-24*/         bytes memory _0x1045d1,
/*LN-25*/         address _0x65ce0c,
/*LN-26*/         address _0xd6cb4d,
/*LN-27*/         bytes32[] memory _0x0f4194,
/*LN-28*/         uint256[] memory _0x70dd97,
/*LN-29*/         bytes memory data,
/*LN-30*/         uint8[] memory v,
/*LN-31*/         bytes32[] memory r,
/*LN-32*/         bytes32[] memory s
/*LN-33*/     ) external {
/*LN-34*/         bytes32 _0x0d961f = _0x0f4194[1];
/*LN-35*/         require(
/*LN-36*/             !_0x390062[_0x0d961f],
/*LN-37*/             "Transaction already processed"
/*LN-38*/         );
/*LN-39*/         require(v.length >= REQUIRED_SIGNATURES, "Insufficient signatures");
/*LN-40*/         require(
/*LN-41*/             v.length == r.length && r.length == s.length,
/*LN-42*/             "Signature length mismatch"
/*LN-43*/         );
/*LN-44*/         uint256 _0x771f54 = _0x70dd97[0];
/*LN-45*/         _0x390062[_0x0d961f] = true;
/*LN-46*/         IERC20(_0xd6cb4d).transfer(_0x65ce0c, _0x771f54);
/*LN-47*/         emit WithdrawalProcessed(_0x0d961f, _0xd6cb4d, _0x65ce0c, _0x771f54);
/*LN-48*/     }
/*LN-49*/     function _0x8cd0a4(address _0x477183) external {
/*LN-50*/         _0x7248ad[_0x477183] = true;
/*LN-51*/     }
/*LN-52*/ }