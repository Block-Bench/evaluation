pragma solidity ^0.8.0;


contract VulnerableParityWalletLibrary {
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;

    bool public initialized;

    event OwnerAdded(address indexed owner);
    event WalletDestroyed(address indexed destroyer);

    function initWallet(
        address[] memory _owners,
        uint256 _required,
        uint256 _daylimit
    ) public {

        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        delete owners;

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

    function isOwnerAddress(address _addr) public view returns (bool) {
        return isOwner[_addr];
    }

    function kill(address payable _to) external {
        require(isOwner[msg.sender], "Not an owner");

        emit WalletDestroyed(msg.sender);

        selfdestruct(_to);
    }

    function execute(address to, uint256 value, bytes memory data) external {
        require(isOwner[msg.sender], "Not an owner");

        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }
}


contract ParityWalletProxy {
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
