/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function balanceOf(address account) external view returns (uint256);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ interface IJar {
/*LN-10*/     function token() external view returns (address);
/*LN-11*/ 
/*LN-12*/     function withdraw(uint256 amount) external;
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ interface IStrategy {
/*LN-16*/     function withdrawAll() external;
/*LN-17*/ 
/*LN-18*/     function withdraw(address token) external;
/*LN-19*/ }
/*LN-20*/ 
/*LN-21*/ contract YieldController {
/*LN-22*/     address public governance;
/*LN-23*/     mapping(address => address) public strategies;
/*LN-24*/ 
/*LN-25*/     constructor() {
/*LN-26*/         governance = msg.sender;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     function swapExactJarForJar(
/*LN-30*/         address _fromJar,
/*LN-31*/         address _toJar,
/*LN-32*/         uint256 _fromJarAmount,
/*LN-33*/         uint256 _toJarMinAmount,
/*LN-34*/         address[] calldata _targets,
/*LN-35*/         bytes[] calldata _data
/*LN-36*/     ) external {
/*LN-37*/         require(_targets.length == _data.length, "Length mismatch");
/*LN-38*/ 
/*LN-39*/         for (uint256 i = 0; i < _targets.length; i++) {
/*LN-40*/             (bool success, ) = _targets[i].call(_data[i]);
/*LN-41*/             require(success, "Call failed");
/*LN-42*/         }
/*LN-43*/ 
/*LN-44*/ 
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/ 
/*LN-48*/     function setStrategy(address jar, address strategy) external {
/*LN-49*/         require(msg.sender == governance, "Not governance");
/*LN-50*/         strategies[jar] = strategy;
/*LN-51*/     }
/*LN-52*/ }
/*LN-53*/ 
/*LN-54*/ contract YieldStrategy {
/*LN-55*/     address public controller;
/*LN-56*/     address public want;
/*LN-57*/ 
/*LN-58*/     constructor(address _controller, address _want) {
/*LN-59*/         controller = _controller;
/*LN-60*/         want = _want;
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/     function withdrawAll() external {
/*LN-65*/ 
/*LN-66*/         uint256 balance = IERC20(want).balanceOf(address(this));
/*LN-67*/         IERC20(want).transfer(controller, balance);
/*LN-68*/     }
/*LN-69*/ 
/*LN-70*/ 
/*LN-71*/     function withdraw(address token) external {
/*LN-72*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-73*/         IERC20(token).transfer(controller, balance);
/*LN-74*/     }
/*LN-75*/ }