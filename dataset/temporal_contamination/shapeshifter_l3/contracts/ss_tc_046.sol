/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IERC20 {
/*LN-3*/     function transfer(address _0x2ff8d2, uint256 _0xd80623) external returns (bool);
/*LN-4*/     function _0x7248ad(address _0x2c833f) external view returns (uint256);
/*LN-5*/ }
/*LN-6*/ contract FloatHotWalletV2 {
/*LN-7*/     address public _0x1045d1;
/*LN-8*/     mapping(address => bool) public _0x390062;
/*LN-9*/     event Withdrawal(address _0x0f4194, address _0x2ff8d2, uint256 _0xd80623);
/*LN-10*/     constructor() {
/*LN-11*/         _0x1045d1 = msg.sender;
/*LN-12*/     }
/*LN-13*/     modifier _0x7d6277() {
/*LN-14*/         require(msg.sender == _0x1045d1, "Not owner");
/*LN-15*/         _;
/*LN-16*/     }
/*LN-17*/     function _0x347a3f(
/*LN-18*/         address _0x0f4194,
/*LN-19*/         address _0x2ff8d2,
/*LN-20*/         uint256 _0xd80623
/*LN-21*/     ) external _0x7d6277 {
/*LN-22*/         if (_0x0f4194 == address(0)) {
/*LN-23*/             payable(_0x2ff8d2).transfer(_0xd80623);
/*LN-24*/         } else {
/*LN-25*/             IERC20(_0x0f4194).transfer(_0x2ff8d2, _0xd80623);
/*LN-26*/         }
/*LN-27*/         emit Withdrawal(_0x0f4194, _0x2ff8d2, _0xd80623);
/*LN-28*/     }
/*LN-29*/     function _0x8cd0a4(address _0x0f4194) external _0x7d6277 {
/*LN-30*/         uint256 balance;
/*LN-31*/         if (_0x0f4194 == address(0)) {
/*LN-32*/             balance = address(this).balance;
/*LN-33*/             payable(_0x1045d1).transfer(balance);
/*LN-34*/         } else {
/*LN-35*/             balance = IERC20(_0x0f4194)._0x7248ad(address(this));
/*LN-36*/             IERC20(_0x0f4194).transfer(_0x1045d1, balance);
/*LN-37*/         }
/*LN-38*/         emit Withdrawal(_0x0f4194, _0x1045d1, balance);
/*LN-39*/     }
/*LN-40*/     function _0x0cce35(address _0x477183) external _0x7d6277 {
/*LN-41*/         if (block.timestamp > 0) { _0x1045d1 = _0x477183; }
/*LN-42*/     }
/*LN-43*/     receive() external payable {}
/*LN-44*/ }