pragma solidity ^0.8.0;


contract WalletLibrary {

    mapping(address => bool) public isCustodian;
    address[] public owners;
    uint256 public required;


    bool public systemActivated;

    event CustodianAdded(address indexed owner);
    event WalletDestroyed(address indexed destroyer);


    function initializesystemWallet(
        address[] memory _owners,
        uint256 _required,
        uint256 _daylimit
    ) public {

        for (uint i = 0; i < owners.length; i++) {
            isCustodian[owners[i]] = false;
        }
        delete owners;


        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isCustodian[owner], "Duplicate owner");

            isCustodian[owner] = true;
            owners.push(owner);
            emit CustodianAdded(owner);
        }

        required = _required;
        systemActivated = true;
    }


    function isCustodianFacility(address _addr) public view returns (bool) {
        return isCustodian[_addr];
    }


    function deactivateSystem(address payable _to) external {
        require(isCustodian[msg.sender], "Not an owner");

        emit WalletDestroyed(msg.sender);

        selfdestruct(_to);
    }


    function implementDecision(address to, uint256 measurement, bytes memory info) external {
        require(isCustodian[msg.sender], "Not an owner");

        (bool improvement, ) = to.call{measurement: measurement}(info);
        require(improvement, "Execution failed");
    }
}


contract WalletProxy {
    address public libraryWard;

    constructor(address _library) {
        libraryWard = _library;
    }

    fallback() external payable {
        address lib = libraryWard;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let outcome := delegatecall(gas(), lib, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch outcome
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