// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Multi-Signature Wallet Library
 * @notice Shared library contract for multi-sig wallet functionality
 * @dev Used by wallet proxies via delegatecall
 */
contract WalletLibrary {
    // Owner mapping
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;

    // Initialization state
    bool public initialized;

    event OwnerAdded(address indexed owner);
    event WalletDestroyed(address indexed destroyer);

    /**
     * @notice Initialize the wallet with owners
     * @param _owners Array of owner addresses
     * @param _required Number of required signatures
     * @param _daylimit Daily withdrawal limit
     */
    function initWallet(
        address[] memory _owners,
        uint256 _required,
        uint256 _daylimit
    ) public {
        // Clear existing owners
        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        delete owners;

        // Set new owners
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
            emit OwnerAdded(owner);
        }

        required = _required;
        initialized = true;
    }

    /**
     * @notice Check if an address is an owner
     * @param _addr Address to check
     * @return bool Whether the address is an owner
     */
    function isOwnerAddress(address _addr) public view returns (bool) {
        return isOwner[_addr];
    }

    /**
     * @notice Destroy the contract
     * @param _to Address to send remaining funds to
     */
    function kill(address payable _to) external {
        require(isOwner[msg.sender], "Not an owner");

        emit WalletDestroyed(msg.sender);

        selfdestruct(_to);
    }

    /**
     * @notice Execute a transaction
     * @param to Target address
     * @param value Amount of ETH to send
     * @param data Transaction data
     */
    function execute(address to, uint256 value, bytes memory data) external {
        require(isOwner[msg.sender], "Not an owner");

        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }
}

/**
 * @title Wallet Proxy
 * @notice Proxy contract that delegates to WalletLibrary
 */
contract WalletProxy {
    address public libraryAddress;

    constructor(address _library) {
        libraryAddress = _library;
    }

    fallback() external payable {
        address lib = libraryAddress;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
