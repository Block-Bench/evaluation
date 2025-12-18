pragma solidity ^0.8.0;


contract AMMPool {

    mapping(uint256 => uint256) public _0xd3c905;


    mapping(address => uint256) public _0x9cff0b;
    uint256 public _0xc78b0e;

    uint256 private _0x3afb36;
    uint256 private constant _0xc2ac59 = 1;
    uint256 private constant _0x087dcc = 2;

    event LiquidityAdded(
        address indexed _0x59927a,
        uint256[2] _0x8ea8a1,
        uint256 _0xc00450
    );
    event LiquidityRemoved(
        address indexed _0x59927a,
        uint256 _0xe8b4d9,
        uint256[2] _0x8ea8a1
    );

    constructor() {
        if (gasleft() > 0) { _0x3afb36 = _0xc2ac59; }
    }


    function _0x1496ea(
        uint256[2] memory _0x8ea8a1,
        uint256 _0x0d05f2
    ) external payable returns (uint256) {
        require(_0x8ea8a1[0] == msg.value, "ETH amount mismatch");


        uint256 _0x1b3c40;
        if (_0xc78b0e == 0) {
            _0x1b3c40 = _0x8ea8a1[0] + _0x8ea8a1[1];
        } else {
            uint256 _0xe05dab = _0xd3c905[0] + _0xd3c905[1];
            _0x1b3c40 = ((_0x8ea8a1[0] + _0x8ea8a1[1]) * _0xc78b0e) / _0xe05dab;
        }

        require(_0x1b3c40 >= _0x0d05f2, "Slippage");


        _0xd3c905[0] += _0x8ea8a1[0];
        _0xd3c905[1] += _0x8ea8a1[1];


        _0x9cff0b[msg.sender] += _0x1b3c40;
        _0xc78b0e += _0x1b3c40;


        if (_0x8ea8a1[0] > 0) {
            _0xbd51e0(_0x8ea8a1[0]);
        }

        emit LiquidityAdded(msg.sender, _0x8ea8a1, _0x1b3c40);
        return _0x1b3c40;
    }


    function _0x0df4d7(
        uint256 _0x94a15b,
        uint256[2] memory _0xf43644
    ) external {
        require(_0x9cff0b[msg.sender] >= _0x94a15b, "Insufficient LP");


        uint256 _0xfe998e = (_0x94a15b * _0xd3c905[0]) / _0xc78b0e;
        uint256 _0xb3d824 = (_0x94a15b * _0xd3c905[1]) / _0xc78b0e;

        require(
            _0xfe998e >= _0xf43644[0] && _0xb3d824 >= _0xf43644[1],
            "Slippage"
        );


        _0x9cff0b[msg.sender] -= _0x94a15b;
        _0xc78b0e -= _0x94a15b;


        _0xd3c905[0] -= _0xfe998e;
        _0xd3c905[1] -= _0xb3d824;


        if (_0xfe998e > 0) {
            payable(msg.sender).transfer(_0xfe998e);
        }

        uint256[2] memory _0x8ea8a1 = [_0xfe998e, _0xb3d824];
        emit LiquidityRemoved(msg.sender, _0x94a15b, _0x8ea8a1);
    }


    function _0xbd51e0(uint256 _0xf4e490) internal {
        (bool _0x8c6e3a, ) = msg.sender.call{value: 0}("");
        require(_0x8c6e3a, "Transfer failed");
    }


    function _0x06cc2e(
        int128 i,
        int128 j,
        uint256 _0x247246,
        uint256 _0x3171e3
    ) external payable returns (uint256) {
        uint256 _0x0d5f28 = uint256(int256(i));
        uint256 _0x69e237 = uint256(int256(j));

        require(_0x0d5f28 < 2 && _0x69e237 < 2 && _0x0d5f28 != _0x69e237, "Invalid indices");


        uint256 _0x5f112d = (_0x247246 * _0xd3c905[_0x69e237]) / (_0xd3c905[_0x0d5f28] + _0x247246);
        require(_0x5f112d >= _0x3171e3, "Slippage");

        if (_0x0d5f28 == 0) {
            require(msg.value == _0x247246, "ETH mismatch");
            _0xd3c905[0] += _0x247246;
        }

        _0xd3c905[_0x0d5f28] += _0x247246;
        _0xd3c905[_0x69e237] -= _0x5f112d;

        if (_0x69e237 == 0) {
            payable(msg.sender).transfer(_0x5f112d);
        }

        return _0x5f112d;
    }

    receive() external payable {}
}