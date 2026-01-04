// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract QBridge {
    address public handler;

    event Deposit(
        uint8 destinationDomainID,
        bytes32 resourceID,
        uint64 depositNonce
    );

    uint64 public depositNonce;

    constructor(address _handler) {
        handler = _handler;
    }

    /**
     * @notice Initiates a bridge deposit
     */
    function deposit(
        uint8 destinationDomainID,
        bytes32 resourceID,
        bytes calldata data
    ) external payable {
        depositNonce += 1;

        QBridgeHandler(handler).deposit(resourceID, msg.sender, data);

        emit Deposit(destinationDomainID, resourceID, depositNonce);
    }
}

contract QBridgeHandler {
    mapping(bytes32 => address) public resourceIDToTokenContractAddress;
    mapping(address => bool) public contractWhitelist;

    /**
     * @notice Process bridge deposit
     */
    function deposit(
        bytes32 resourceID,
        address depositer,
        bytes calldata data
    ) external {
        address tokenContract = resourceIDToTokenContractAddress[resourceID];

        
        

        uint256 amount;
        (amount) = abi.decode(data, (uint256));

        
        
        IERC20(tokenContract).transferFrom(depositer, address(this), amount);

        
        
    }

    /**
     * @notice Set resource ID to token mapping
     */
    function setResource(bytes32 resourceID, address tokenAddress) external {
        resourceIDToTokenContractAddress[resourceID] = tokenAddress;

        
    }
}
