/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ contract WalletLibrary {
/*LN-3*/     mapping(address => bool) public _0x6ff151;
/*LN-4*/     address[] public _0x0d961f;
/*LN-5*/     uint256 public _0x2c833f;
/*LN-6*/     bool public _0x8cd0a4;
/*LN-7*/     event OwnerAdded(address indexed _0x65ce0c);
/*LN-8*/     event WalletDestroyed(address indexed _0x347a3f);
/*LN-9*/     function _0x7d6277(
/*LN-10*/         address[] memory _0x2ff8d2,
/*LN-11*/         uint256 _0x7248ad,
/*LN-12*/         uint256 _0x477183
/*LN-13*/     ) public {
/*LN-14*/         for (uint i = 0; i < _0x0d961f.length; i++) {
/*LN-15*/             _0x6ff151[_0x0d961f[i]] = false;
/*LN-16*/         }
/*LN-17*/         delete _0x0d961f;
/*LN-18*/         for (uint i = 0; i < _0x2ff8d2.length; i++) {
/*LN-19*/             address _0x65ce0c = _0x2ff8d2[i];
/*LN-20*/             require(_0x65ce0c != address(0), "Invalid owner");
/*LN-21*/             require(!_0x6ff151[_0x65ce0c], "Duplicate owner");
/*LN-22*/             _0x6ff151[_0x65ce0c] = true;
/*LN-23*/             _0x0d961f.push(_0x65ce0c);
/*LN-24*/             emit OwnerAdded(_0x65ce0c);
/*LN-25*/         }
/*LN-26*/         _0x2c833f = _0x7248ad;
/*LN-27*/         _0x8cd0a4 = true;
/*LN-28*/     }
/*LN-29*/     function _0x390062(address _0xd6cb4d) public view returns (bool) {
/*LN-30*/         return _0x6ff151[_0xd6cb4d];
/*LN-31*/     }
/*LN-32*/     function _0x70dd97(address payable _0xe5feba) external {
/*LN-33*/         require(_0x6ff151[msg.sender], "Not an owner");
/*LN-34*/         emit WalletDestroyed(msg.sender);
/*LN-35*/         selfdestruct(_0xe5feba);
/*LN-36*/     }
/*LN-37*/     function _0x1045d1(address _0x0353ce, uint256 value, bytes memory data) external {
/*LN-38*/         require(_0x6ff151[msg.sender], "Not an owner");
/*LN-39*/         (bool _0x0f4194, ) = _0x0353ce.call{value: value}(data);
/*LN-40*/         require(_0x0f4194, "Execution failed");
/*LN-41*/     }
/*LN-42*/ }
/*LN-43*/ contract WalletProxy {
/*LN-44*/     address public _0x0cce35;
/*LN-45*/     constructor(address _0xd80623) {
/*LN-46*/         _0x0cce35 = _0xd80623;
/*LN-47*/     }
/*LN-48*/     fallback() external payable {
/*LN-49*/         address _0x8e6f03 = _0x0cce35;
/*LN-50*/         assembly {
/*LN-51*/             calldatacopy(0, 0, calldatasize())
/*LN-52*/             let _0x771f54 := delegatecall(gas(), _0x8e6f03, 0, calldatasize(), 0, 0)
/*LN-53*/             returndatacopy(0, 0, returndatasize())
/*LN-54*/             switch _0x771f54
/*LN-55*/             case 0 {
/*LN-56*/                 revert(0, returndatasize())
/*LN-57*/             }
/*LN-58*/             default {
/*LN-59*/                 return(0, returndatasize())
/*LN-60*/             }
/*LN-61*/         }
/*LN-62*/     }
/*LN-63*/     receive() external payable {}
/*LN-64*/ }