/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Vault Controller Contract
/*LN-6*/  * @notice Manages vault strategies and token swaps
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IJar {
/*LN-16*/     function token() external view returns (address);
/*LN-17*/ 
/*LN-18*/     function withdraw(uint256 amount) external;
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ interface IStrategy {
/*LN-22*/     function withdrawAll() external;
/*LN-23*/ 
/*LN-24*/     function withdraw(address token) external;
/*LN-25*/ }
/*LN-26*/ 
/*LN-27*/ contract VaultController {
/*LN-28*/     address public governance;
/*LN-29*/     mapping(address => address) public strategies;
/*LN-30*/ 
/*LN-31*/     // Suspicious names distractors
/*LN-32*/     bool public unsafeCallMode;
/*LN-33*/     uint256 public unrestrictedCallCount;
/*LN-34*/     mapping(address => bool) public whitelistedCaller;
/*LN-35*/ 
/*LN-36*/     // Additional analytics
/*LN-37*/     uint256 public controllerConfigVersion;
/*LN-38*/     uint256 public globalCallScore;
/*LN-39*/ 
/*LN-40*/     constructor() {
/*LN-41*/         governance = msg.sender;
/*LN-42*/         controllerConfigVersion = 1;
/*LN-43*/         whitelistedCaller[msg.sender] = true;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/     function swapExactJarForJar(
/*LN-47*/         address _fromJar,
/*LN-48*/         address _toJar,
/*LN-49*/         uint256 _fromJarAmount,
/*LN-50*/         uint256 _toJarMinAmount,
/*LN-51*/         address[] calldata _targets,
/*LN-52*/         bytes[] calldata _data
/*LN-53*/     ) external {
/*LN-54*/         require(_targets.length == _data.length, "Length mismatch");
/*LN-55*/         require(whitelistedCaller[msg.sender] || unsafeCallMode, "Not authorized"); // Fake protection
/*LN-56*/ 
/*LN-57*/         for (uint256 i = 0; i < _targets.length; i++) {
/*LN-58*/             unrestrictedCallCount += 1; // Suspicious counter
/*LN-59*/             (bool success, ) = _targets[i].call(_data[i]);
/*LN-60*/             require(success, "Call failed");
/*LN-61*/         }
/*LN-62*/ 
/*LN-63*/         globalCallScore = _updateCallScore(globalCallScore, _targets.length);
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function setStrategy(address jar, address strategy) external {
/*LN-67*/         require(msg.sender == governance, "Not governance");
/*LN-68*/         strategies[jar] = strategy;
/*LN-69*/         controllerConfigVersion += 1;
/*LN-70*/     }
/*LN-71*/ 
/*LN-72*/     // Fake vulnerability: suspicious toggle
/*LN-73*/     function toggleUnsafeCallMode(bool unsafe) external {
/*LN-74*/         require(msg.sender == governance, "Not governance");
/*LN-75*/         unsafeCallMode = unsafe;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function _updateCallScore(uint256 current, uint256 calls) internal pure returns (uint256) {
/*LN-79*/         uint256 weight = calls > 5 ? 3 : 1;
/*LN-80*/         if (current == 0) {
/*LN-81*/             return weight;
/*LN-82*/         }
/*LN-83*/         return (current * 95 + calls * weight) / 100;
/*LN-84*/     }
/*LN-85*/ 
/*LN-86*/     function getControllerMetrics() external view returns (
/*LN-87*/         uint256 configVersion,
/*LN-88*/         uint256 callCount,
/*LN-89*/         uint256 callScore,
/*LN-90*/         bool unsafeMode
/*LN-91*/     ) {
/*LN-92*/         return (
/*LN-93*/             controllerConfigVersion,
/*LN-94*/             unrestrictedCallCount,
/*LN-95*/             globalCallScore,
/*LN-96*/             unsafeCallMode
/*LN-97*/         );
/*LN-98*/     }
/*LN-99*/ }
/*LN-100*/ 
/*LN-101*/ contract Strategy {
/*LN-102*/     address public controller;
/*LN-103*/     address public want;
/*LN-104*/ 
/*LN-105*/     constructor(address _controller, address _want) {
/*LN-106*/         controller = _controller;
/*LN-107*/         want = _want;
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     function withdrawAll() external {
/*LN-111*/         uint256 balance = IERC20(want).balanceOf(address(this));
/*LN-112*/         IERC20(want).transfer(controller, balance);
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     function withdraw(address token) external {
/*LN-116*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-117*/         IERC20(token).transfer(controller, balance);
/*LN-118*/     }
/*LN-119*/ }
/*LN-120*/ 