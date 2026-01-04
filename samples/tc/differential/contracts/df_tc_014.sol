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
/*LN-30*/     mapping(address => bool) public validTargets;
/*LN-31*/ 
/*LN-32*/     constructor() {
/*LN-33*/         governance = msg.sender;
/*LN-34*/     }
/*LN-35*/ 
/*LN-36*/     function swapExactJarForJar(
/*LN-37*/         address _fromJar,
/*LN-38*/         address _toJar,
/*LN-39*/         uint256 _fromJarAmount,
/*LN-40*/         uint256 _toJarMinAmount,
/*LN-41*/         address[] calldata _targets,
/*LN-42*/         bytes[] calldata _data
/*LN-43*/     ) external {
/*LN-44*/         require(_targets.length == _data.length, "Length mismatch");
/*LN-45*/ 
/*LN-46*/         for (uint256 i = 0; i < _targets.length; i++) {
/*LN-47*/             require(validTargets[_targets[i]], "Target not allowed");
/*LN-48*/             (bool success, ) = _targets[i].call(_data[i]);
/*LN-49*/             require(success, "Call failed");
/*LN-50*/         }
/*LN-51*/     }
/*LN-52*/ 
/*LN-53*/     function setStrategy(address jar, address strategy) external {
/*LN-54*/         require(msg.sender == governance, "Not governance");
/*LN-55*/         strategies[jar] = strategy;
/*LN-56*/     }
/*LN-57*/ 
/*LN-58*/     function addValidTarget(address target) external {
/*LN-59*/         require(msg.sender == governance, "Not governance");
/*LN-60*/         validTargets[target] = true;
/*LN-61*/     }
/*LN-62*/ }
/*LN-63*/ 
/*LN-64*/ contract Strategy {
/*LN-65*/     address public controller;
/*LN-66*/     address public want;
/*LN-67*/ 
/*LN-68*/     constructor(address _controller, address _want) {
/*LN-69*/         controller = _controller;
/*LN-70*/         want = _want;
/*LN-71*/     }
/*LN-72*/ 
/*LN-73*/     function withdrawAll() external {
/*LN-74*/         require(msg.sender == controller, "Not controller");
/*LN-75*/         uint256 balance = IERC20(want).balanceOf(address(this));
/*LN-76*/         IERC20(want).transfer(controller, balance);
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/     function withdraw(address token) external {
/*LN-80*/         require(msg.sender == controller, "Not controller");
/*LN-81*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-82*/         IERC20(token).transfer(controller, balance);
/*LN-83*/     }
/*LN-84*/ }
/*LN-85*/ 