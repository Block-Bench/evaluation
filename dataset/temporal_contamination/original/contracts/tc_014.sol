/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Pickle Finance - Arbitrary Call Vulnerability
/*LN-6*/  * @notice This contract demonstrates the vulnerability that led to the Pickle hack
/*LN-7*/  * @dev November 21, 2020 - $20M stolen through arbitrary contract calls
/*LN-8*/  *
/*LN-9*/  * VULNERABILITY: Arbitrary external calls in swap function allowing malicious operations
/*LN-10*/  *
/*LN-11*/  * ROOT CAUSE:
/*LN-12*/  * The Controller's swapExactJarForJar() function accepts arrays of target addresses
/*LN-13*/  * and calldata, then makes arbitrary external calls to these targets. An attacker
/*LN-14*/  * can craft malicious calldata that calls privileged functions on strategy contracts,
/*LN-15*/  * such as withdrawAll() or withdraw(), draining funds.
/*LN-16*/  *
/*LN-17*/  * ATTACK VECTOR:
/*LN-18*/  * 1. Create fake "jar" (vault) contracts that return attacker-controlled addresses
/*LN-19*/  * 2. Call swapExactJarForJar() with these fake jars
/*LN-20*/  * 3. Pass target addresses pointing to real strategy contracts
/*LN-21*/  * 4. Pass calldata that encodes calls to withdrawAll() or other privileged functions
/*LN-22*/  * 5. Controller makes these calls without proper authorization checks
/*LN-23*/  * 6. Strategy contracts execute withdrawAll(), sending funds to attacker
/*LN-24*/  * 7. Repeat with multiple strategies to drain protocol
/*LN-25*/  *
/*LN-26*/  * The vulnerability is that the Controller trusts user-provided targets and calldata
/*LN-27*/  * without validating what functions are being called or who should be able to call them.
/*LN-28*/  */
/*LN-29*/ 
/*LN-30*/ interface IERC20 {
/*LN-31*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-32*/ 
/*LN-33*/     function balanceOf(address account) external view returns (uint256);
/*LN-34*/ }
/*LN-35*/ 
/*LN-36*/ interface IJar {
/*LN-37*/     function token() external view returns (address);
/*LN-38*/ 
/*LN-39*/     function withdraw(uint256 amount) external;
/*LN-40*/ }
/*LN-41*/ 
/*LN-42*/ interface IStrategy {
/*LN-43*/     function withdrawAll() external;
/*LN-44*/ 
/*LN-45*/     function withdraw(address token) external;
/*LN-46*/ }
/*LN-47*/ 
/*LN-48*/ contract VulnerablePickleController {
/*LN-49*/     address public governance;
/*LN-50*/     mapping(address => address) public strategies; // jar => strategy
/*LN-51*/ 
/*LN-52*/     constructor() {
/*LN-53*/         governance = msg.sender;
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/     /**
/*LN-57*/      * @notice Swap tokens between jars through strategies
/*LN-58*/      * @param _fromJar Source jar address
/*LN-59*/      * @param _toJar Destination jar address
/*LN-60*/      * @param _fromJarAmount Amount to swap
/*LN-61*/      * @param _toJarMinAmount Minimum amount to receive
/*LN-62*/      * @param _targets Array of target contract addresses to call
/*LN-63*/      * @param _data Array of calldata for each target
/*LN-64*/      *
/*LN-65*/      * VULNERABILITY IS HERE:
/*LN-66*/      * The function makes arbitrary calls to user-provided targets with user-provided data.
/*LN-67*/      * There are no checks on:
/*LN-68*/      * 1. What contracts can be called (_targets)
/*LN-69*/      * 2. What functions can be called (encoded in _data)
/*LN-70*/      * 3. Whether the caller should have permission to make these calls
/*LN-71*/      *
/*LN-72*/      * Vulnerable sequence:
/*LN-73*/      * 1. Function accepts arbitrary _targets and _data arrays (line 81-82)
/*LN-74*/      * 2. Loops through and calls each target (line 88-91)
/*LN-75*/      * 3. No validation of targets or data
/*LN-76*/      * 4. Attacker can call withdrawAll() on strategies
/*LN-77*/      * 5. Attacker can call any function on any contract
/*LN-78*/      * 6. Funds drained from strategies
/*LN-79*/      */
/*LN-80*/     function swapExactJarForJar(
/*LN-81*/         address _fromJar,
/*LN-82*/         address _toJar,
/*LN-83*/         uint256 _fromJarAmount,
/*LN-84*/         uint256 _toJarMinAmount,
/*LN-85*/         address[] calldata _targets,
/*LN-86*/         bytes[] calldata _data
/*LN-87*/     ) external {
/*LN-88*/         require(_targets.length == _data.length, "Length mismatch");
/*LN-89*/ 
/*LN-90*/         // VULNERABLE: Make arbitrary calls without validation
/*LN-91*/         for (uint256 i = 0; i < _targets.length; i++) {
/*LN-92*/             (bool success, ) = _targets[i].call(_data[i]);
/*LN-93*/             require(success, "Call failed");
/*LN-94*/         }
/*LN-95*/ 
/*LN-96*/         // The rest of swap logic would go here
/*LN-97*/         // But it doesn't matter because attacker already drained funds
/*LN-98*/     }
/*LN-99*/ 
/*LN-100*/     /**
/*LN-101*/      * @notice Set strategy for a jar
/*LN-102*/      * @dev Only governance should call this
/*LN-103*/      */
/*LN-104*/     function setStrategy(address jar, address strategy) external {
/*LN-105*/         require(msg.sender == governance, "Not governance");
/*LN-106*/         strategies[jar] = strategy;
/*LN-107*/     }
/*LN-108*/ }
/*LN-109*/ 
/*LN-110*/ /**
/*LN-111*/  * Example Strategy contract that can be exploited:
/*LN-112*/  */
/*LN-113*/ contract PickleStrategy {
/*LN-114*/     address public controller;
/*LN-115*/     address public want; // The token this strategy manages
/*LN-116*/ 
/*LN-117*/     constructor(address _controller, address _want) {
/*LN-118*/         controller = _controller;
/*LN-119*/         want = _want;
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     /**
/*LN-123*/      * @notice Withdraw all funds from strategy
/*LN-124*/      * @dev Should only be callable by controller, but no check!
/*LN-125*/      */
/*LN-126*/     function withdrawAll() external {
/*LN-127*/         // VULNERABLE: No access control!
/*LN-128*/         // Should check: require(msg.sender == controller, "Not controller");
/*LN-129*/ 
/*LN-130*/         uint256 balance = IERC20(want).balanceOf(address(this));
/*LN-131*/         IERC20(want).transfer(controller, balance);
/*LN-132*/     }
/*LN-133*/ 
/*LN-134*/     /**
/*LN-135*/      * @notice Withdraw specific token
/*LN-136*/      * @dev Also lacks access control
/*LN-137*/      */
/*LN-138*/     function withdraw(address token) external {
/*LN-139*/         // VULNERABLE: No access control!
/*LN-140*/         uint256 balance = IERC20(token).balanceOf(address(this));
/*LN-141*/         IERC20(token).transfer(controller, balance);
/*LN-142*/     }
/*LN-143*/ }
/*LN-144*/ 
/*LN-145*/ /**
/*LN-146*/  * Example attack flow:
/*LN-147*/  *
/*LN-148*/  * 1. Attacker creates FakeJar contract:
/*LN-149*/  *    contract FakeJar {
/*LN-150*/  *        address public token;
/*LN-151*/  *        constructor(address _token) { token = _token; }
/*LN-152*/  *    }
/*LN-153*/  *
/*LN-154*/  * 2. Attacker encodes malicious calldata:
/*LN-155*/  *    bytes memory withdrawAllData = abi.encodeWithSignature("withdrawAll()");
/*LN-156*/  *    bytes memory withdrawData = abi.encodeWithSignature("withdraw(address)", DAI_ADDRESS);
/*LN-157*/  *
/*LN-158*/  * 3. Attacker calls controller.swapExactJarForJar():
/*LN-159*/  *    - _fromJar = address(fakeJar1)
/*LN-160*/  *    - _toJar = address(fakeJar2)
/*LN-161*/  *    - _fromJarAmount = 0
/*LN-162*/  *    - _toJarMinAmount = 0
/*LN-163*/  *    - _targets = [strategyAddress1, strategyAddress2, ...]
/*LN-164*/  *    - _data = [withdrawAllData, withdrawData, ...]
/*LN-165*/  *
/*LN-166*/  * 4. Controller calls strategy.withdrawAll() on behalf of attacker
/*LN-167*/  * 5. Strategy sends all funds to controller (which is compromised in this flow)
/*LN-168*/  * 6. Attacker repeats for all strategies
/*LN-169*/  * 7. $20M drained
/*LN-170*/  *
/*LN-171*/  * REAL-WORLD IMPACT:
/*LN-172*/  * - $20M stolen in November 2020
/*LN-173*/  * - DAI strategy completely drained
/*LN-174*/  * - Demonstrated danger of arbitrary external calls
/*LN-175*/  * - Led to stricter function access controls in DeFi
/*LN-176*/  *
/*LN-177*/  * FIX:
/*LN-178*/  * 1. Remove arbitrary call functionality entirely:
/*LN-179*/  *
/*LN-180*/  * function swapExactJarForJar(
/*LN-181*/  *     address _fromJar,
/*LN-182*/  *     address _toJar,
/*LN-183*/  *     uint256 _fromJarAmount,
/*LN-184*/  *     uint256 _toJarMinAmount
/*LN-185*/  * ) external {
/*LN-186*/  *     // Implement swap logic directly, no arbitrary calls
/*LN-187*/  *     address fromStrategy = strategies[_fromJar];
/*LN-188*/  *     address toStrategy = strategies[_toJar];
/*LN-189*/  *
/*LN-190*/  *     // Call specific, known functions only
/*LN-191*/  *     IStrategy(fromStrategy).withdraw(_fromJarAmount);
/*LN-192*/  *     IStrategy(toStrategy).deposit(_fromJarAmount);
/*LN-193*/  * }
/*LN-194*/  *
/*LN-195*/  * 2. Add strict access control to strategy functions:
/*LN-196*/  *
/*LN-197*/  * function withdrawAll() external {
/*LN-198*/  *     require(msg.sender == controller, "Only controller");
/*LN-199*/  *     uint256 balance = IERC20(want).balanceOf(address(this));
/*LN-200*/  *     IERC20(want).transfer(controller, balance);
/*LN-201*/  * }
/*LN-202*/  *
/*LN-203*/  * 3. Whitelist allowed targets and function selectors:
/*LN-204*/  *
/*LN-205*/  * mapping(address => mapping(bytes4 => bool)) public allowedCalls;
/*LN-206*/  *
/*LN-207*/  * function swapExactJarForJar(...) external {
/*LN-208*/  *     for (uint256 i = 0; i < _targets.length; i++) {
/*LN-209*/  *         bytes4 selector = bytes4(_data[i]);
/*LN-210*/  *         require(allowedCalls[_targets[i]][selector], "Call not allowed");
/*LN-211*/  *         (bool success, ) = _targets[i].call(_data[i]);
/*LN-212*/  *         require(success, "Call failed");
/*LN-213*/  *     }
/*LN-214*/  * }
/*LN-215*/  *
/*LN-216*/  *
/*LN-217*/  * KEY LESSON:
/*LN-218*/  * Never allow arbitrary external calls with user-provided targets and calldata.
/*LN-219*/  * Always validate what contracts and functions can be called.
/*LN-220*/  * Implement strict access control on all privileged functions.
/*LN-221*/  * If arbitrary calls are needed, use strict whitelisting.
/*LN-222*/  */
/*LN-223*/ 