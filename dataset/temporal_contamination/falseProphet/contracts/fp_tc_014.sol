/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/

/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/

/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/

/*LN-10*/ interface IJar {
/*LN-11*/     function token() external view returns (address);
/*LN-12*/

/*LN-13*/     function withdraw(uint256 amount) external;
/*LN-14*/ }
/*LN-15*/

/*LN-16*/ interface IStrategy {
/*LN-17*/     function withdrawAll() external;
/*LN-18*/

/*LN-19*/     function withdraw(address token) external;
/*LN-20*/ }
/*LN-21*/

/**
 * @title YieldController
 * @author yield Finance
 * @notice Yield farming strategy controller for jar management
 * @dev Audited by MixBytes (Q3 2020) - All findings resolved
 * @dev Manages strategy deployment and jar-to-jar swaps
 * @dev Governance-controlled strategy assignments
 * @custom:security-contact security@yield.finance
 */
/*LN-22*/ contract YieldController {
/*LN-23*/     address public governance;
/*LN-24*/     mapping(address => address) public strategies; // jar => strategy
/*LN-25*/ 
/*LN-26*/     constructor() {
/*LN-27*/         governance = msg.sender;
/*LN-28*/     }
/*LN-29*/ 
    /**
     * @notice Swap tokens between jars via aggregator routing
     * @dev Executes swap path through provided targets
     * @dev Validates array lengths for consistency
     * @param _fromJar Source jar address
     * @param _toJar Destination jar address
     * @param _fromJarAmount Amount to swap from source
     * @param _toJarMinAmount Minimum expected output
     * @param _targets Swap route target contracts
     * @param _data Calldata for each target
     */
/*LN-30*/     function swapExactJarForJar(
/*LN-31*/         address _fromJar,
/*LN-32*/         address _toJar,
/*LN-33*/         uint256 _fromJarAmount,
/*LN-34*/         uint256 _toJarMinAmount,
/*LN-35*/         address[] calldata _targets,
/*LN-36*/         bytes[] calldata _data
/*LN-37*/     ) external {
/*LN-38*/         require(_targets.length == _data.length, "Length mismatch");
/*LN-39*/

            // Execute swap route through aggregator
/*LN-40*/         for (uint256 i = 0; i < _targets.length; i++) {
            // Call each target in swap path
/*LN-41*/             (bool success, ) = _targets[i].call(_data[i]);
/*LN-42*/             require(success, "Call failed");
/*LN-43*/         }
/*LN-44*/

/*LN-45*/         // The rest of swap logic would go here
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     /**
/*LN-49*/      * @notice Set strategy for a jar
/*LN-50*/      * @dev Only governance should call this
/*LN-51*/      */
/*LN-52*/     function setStrategy(address jar, address strategy) external {
/*LN-53*/         require(msg.sender == governance, "Not governance");
/*LN-54*/         strategies[jar] = strategy;
/*LN-55*/     }
/*LN-56*/ }
/*LN-57*/

/**
 * @title YieldStrategy
 * @author yield Finance
 * @notice Yield farming strategy for token management
 * @dev Works in conjunction with YieldController
 * @dev Manages want token deposits and withdrawals
 */
/*LN-58*/ contract YieldStrategy {
    /// @dev Controller contract for coordination
/*LN-59*/     address public controller;
    /// @dev Target asset for this strategy
/*LN-60*/     address public want; // The token this strategy manages
/*LN-61*/

/*LN-62*/     constructor(address _controller, address _want) {
/*LN-63*/         controller = _controller;
/*LN-64*/         want = _want;
/*LN-65*/     }
/*LN-66*/

    /**
     * @notice Withdraw all funds back to controller
     * @dev Transfers entire want balance to controller
     */
/*LN-71*/     function withdrawAll() external {
            // Transfer all holdings to controller
/*LN-72*/         // Controller coordination for fund management
/*LN-73*/

/*LN-74*/         uint256 balance = IERC20(want).balanceOf(address(this));
            // Send balance to controller
/*LN-75*/         IERC20(want).transfer(controller, balance);
/*LN-76*/     }
/*LN-77*/

    /**
     * @notice Withdraw specific token to controller
     * @dev Used for token recovery and rebalancing
     * @param token Address of token to withdraw
     */
/*LN-82*/     function withdraw(address token) external {
/*LN-83*/         uint256 balance = IERC20(token).balanceOf(address(this));
            // Transfer to controller
/*LN-84*/         IERC20(token).transfer(controller, balance);
/*LN-85*/     }
/*LN-86*/ }
/*LN-87*/