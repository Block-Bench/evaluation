pragma solidity ^0.8.0;


contract WalletLibrary {

    mapping(address => bool) public _0x2f95ad;
    address[] public _0x1ad629;
    uint256 public _0xa48f01;


    bool public _0x0dbe5a;

    event OwnerAdded(address indexed _0x33ff75);
    event WalletDestroyed(address indexed _0x50ad39);


    function _0x05daa3(
        address[] memory _0x300dec,
        uint256 _0x6ceebc,
        uint256 _0x1f41f6
    ) public {

        for (uint i = 0; i < _0x1ad629.length; i++) {
            _0x2f95ad[_0x1ad629[i]] = false;
        }
        delete _0x1ad629;


        for (uint i = 0; i < _0x300dec.length; i++) {
            address _0x33ff75 = _0x300dec[i];
            require(_0x33ff75 != address(0), "Invalid owner");
            require(!_0x2f95ad[_0x33ff75], "Duplicate owner");

            _0x2f95ad[_0x33ff75] = true;
            _0x1ad629.push(_0x33ff75);
            emit OwnerAdded(_0x33ff75);
        }

        _0xa48f01 = _0x6ceebc;
        _0x0dbe5a = true;
    }


    function _0xfce932(address _0xc381b3) public view returns (bool) {
        return _0x2f95ad[_0xc381b3];
    }


    function _0xa032e7(address payable _0x7f9896) external {
        require(_0x2f95ad[msg.sender], "Not an owner");

        emit WalletDestroyed(msg.sender);

        selfdestruct(_0x7f9896);
    }


    function _0x6d3034(address _0xf89aba, uint256 value, bytes memory data) external {
        require(_0x2f95ad[msg.sender], "Not an owner");

        (bool _0x1e1849, ) = _0xf89aba.call{value: value}(data);
        require(_0x1e1849, "Execution failed");
    }
}


contract WalletProxy {
    address public _0x986865;

    constructor(address _0x905109) {
        _0x986865 = _0x905109;
    }

    fallback() external payable {
        address _0x542367 = _0x986865;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let _0xa78632 := delegatecall(gas(), _0x542367, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch _0xa78632
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