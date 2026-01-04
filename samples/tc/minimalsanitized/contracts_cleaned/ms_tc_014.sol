// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IJar {
    function token() external view returns (address);

    function withdraw(uint256 amount) external;
}

interface IStrategy {
    function withdrawAll() external;

    function withdraw(address token) external;
}

contract PickleController {
    address public governance;
    mapping(address => address) public strategies; // jar => strategy

    constructor() {
        governance = msg.sender;
    }

    function swapExactJarForJar(
        address _fromJar,
        address _toJar,
        uint256 _fromJarAmount,
        uint256 _toJarMinAmount,
        address[] calldata _targets,
        bytes[] calldata _data
    ) external {
        require(_targets.length == _data.length, "Length mismatch");

        for (uint256 i = 0; i < _targets.length; i++) {
            (bool success, ) = _targets[i].call(_data[i]);
            require(success, "Call failed");
        }

        // The rest of swap logic would go here
    }

    /**
     * @notice Set strategy for a jar
     * @dev Only governance should call this
     */
    function setStrategy(address jar, address strategy) external {
        require(msg.sender == governance, "Not governance");
        strategies[jar] = strategy;
    }
}

contract PickleStrategy {
    address public controller;
    address public want; // The token this strategy manages

    constructor(address _controller, address _want) {
        controller = _controller;
        want = _want;
    }

    /**
     * @notice Withdraw all funds from strategy
     * 
     */
    function withdrawAll() external {
        

        uint256 balance = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(controller, balance);
    }

    /**
     * @notice Withdraw specific token
     * @dev Also lacks access control
     */
    function withdraw(address token) external {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(controller, balance);
    }
}
