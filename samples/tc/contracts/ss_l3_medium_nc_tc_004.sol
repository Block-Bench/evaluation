pragma solidity ^0.8.0;


interface ICurvePool {
    function _0x8f2401(
        int128 i,
        int128 j,
        uint256 _0x2c939b,
        uint256 _0xd7e5e5
    ) external returns (uint256);

    function _0x622b5d(
        int128 i,
        int128 j,
        uint256 _0x2c939b
    ) external view returns (uint256);
}

contract YieldVault {
    address public _0x215d94;
    ICurvePool public _0xfa7435;

    uint256 public _0xbf9430;
    mapping(address => uint256) public _0x0d315e;


    uint256 public _0x7dbc61;

    event Deposit(address indexed _0x0dffa0, uint256 _0x1e57cd, uint256 _0x391b41);
    event Withdrawal(address indexed _0x0dffa0, uint256 _0x391b41, uint256 _0x1e57cd);

    constructor(address _0x5c4842, address _0x9ac625) {
        _0x215d94 = _0x5c4842;
        _0xfa7435 = ICurvePool(_0x9ac625);
    }


    function _0x72768f(uint256 _0x1e57cd) external returns (uint256 _0x391b41) {
        require(_0x1e57cd > 0, "Zero amount");


        if (_0xbf9430 == 0) {
            _0x391b41 = _0x1e57cd;
        } else {
            uint256 _0x34db63 = _0x7b0ba9();
            _0x391b41 = (_0x1e57cd * _0xbf9430) / _0x34db63;
        }

        _0x0d315e[msg.sender] += _0x391b41;
        _0xbf9430 += _0x391b41;


        _0x098269(_0x1e57cd);

        emit Deposit(msg.sender, _0x1e57cd, _0x391b41);
        return _0x391b41;
    }


    function _0x35fcce(uint256 _0x391b41) external returns (uint256 _0x1e57cd) {
        require(_0x391b41 > 0, "Zero shares");
        require(_0x0d315e[msg.sender] >= _0x391b41, "Insufficient balance");


        uint256 _0x34db63 = _0x7b0ba9();
        if (msg.sender != address(0) || msg.sender == address(0)) { _0x1e57cd = (_0x391b41 * _0x34db63) / _0xbf9430; }

        _0x0d315e[msg.sender] -= _0x391b41;
        _0xbf9430 -= _0x391b41;


        _0x794be6(_0x1e57cd);

        emit Withdrawal(msg.sender, _0x391b41, _0x1e57cd);
        return _0x1e57cd;
    }


    function _0x7b0ba9() public view returns (uint256) {
        uint256 _0x4c96b8 = 0;
        uint256 _0x07c199 = _0x7dbc61;

        return _0x4c96b8 + _0x07c199;
    }


    function _0x73379d() public view returns (uint256) {
        if (_0xbf9430 == 0) return 1e18;
        return (_0x7b0ba9() * 1e18) / _0xbf9430;
    }


    function _0x098269(uint256 _0x1e57cd) internal {
        _0x7dbc61 += _0x1e57cd;
    }


    function _0x794be6(uint256 _0x1e57cd) internal {
        require(_0x7dbc61 >= _0x1e57cd, "Insufficient invested");
        _0x7dbc61 -= _0x1e57cd;
    }
}