// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract MyERC777 is ERC777 {
    constructor(
        uint256 initialSupply
    ) ERC777("Gold", "GLD", new address[](0)) {}

    function mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) public returns (bool) {
        _mint(account, amount, userData, operatorData);
        return true;
    }
}

contract SimpleBank {
    ERC777 private token;
    uint maxMintsPerAddress = 1000;
    mapping(address => uint256) public _mints;
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(address nftAddress) {
        token = ERC777(nftAddress);

        // Register IERC1820Registry
        IERC1820Registry registry = IERC1820Registry(
            address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24)
        );
        registry.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    function claim(address account, uint256 amount) public returns (bool) {
        require(
            _mints[account] + amount <= maxMintsPerAddress,
            "Exceeds max mints per address"
        );

        token.transfer(account, amount);
        _mints[account] += amount;

        return true;
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {}

    receive() external payable {}
}
