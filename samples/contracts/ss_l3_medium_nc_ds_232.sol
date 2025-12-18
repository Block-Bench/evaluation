pragma solidity ^0.4.16;

library SafeMath {
  function _0x3958ec(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function _0xea3031(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function _0xd2f913(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function _0x4009f1(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public _0x8b450b;
  function _0xb83182(address _0xf35562) public constant returns (uint256);
  function transfer(address _0x60fd31, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed _0x60fd31, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) _0xcc9816;

  function transfer(address _0x4edb90, uint256 _0xa5b9f8) public returns (bool) {
    require(_0x4edb90 != address(0));
    require(_0xa5b9f8 > 0 && _0xa5b9f8 <= _0xcc9816[msg.sender]);


    _0xcc9816[msg.sender] = _0xcc9816[msg.sender]._0xd2f913(_0xa5b9f8);
    _0xcc9816[_0x4edb90] = _0xcc9816[_0x4edb90]._0x4009f1(_0xa5b9f8);
    Transfer(msg.sender, _0x4edb90, _0xa5b9f8);
    return true;
  }

  function _0xb83182(address _0x34ad93) public constant returns (uint256 balance) {
    return _0xcc9816[_0x34ad93];
  }
}

contract ERC20 is ERC20Basic {
  function _0x869f66(address _0x19615c, address _0xe1e9a3) public constant returns (uint256);
  function _0x35b384(address from, address _0x60fd31, uint256 value) public returns (bool);
  function _0xddf034(address _0xe1e9a3, uint256 value) public returns (bool);
  event Approval(address indexed _0x19615c, address indexed _0xe1e9a3, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal _0x3db5ad;

  function _0x35b384(address _0x871c33, address _0x4edb90, uint256 _0xa5b9f8) public returns (bool) {
    require(_0x4edb90 != address(0));
    require(_0xa5b9f8 > 0 && _0xa5b9f8 <= _0xcc9816[_0x871c33]);
    require(_0xa5b9f8 <= _0x3db5ad[_0x871c33][msg.sender]);

    _0xcc9816[_0x871c33] = _0xcc9816[_0x871c33]._0xd2f913(_0xa5b9f8);
    _0xcc9816[_0x4edb90] = _0xcc9816[_0x4edb90]._0x4009f1(_0xa5b9f8);
    _0x3db5ad[_0x871c33][msg.sender] = _0x3db5ad[_0x871c33][msg.sender]._0xd2f913(_0xa5b9f8);
    Transfer(_0x871c33, _0x4edb90, _0xa5b9f8);
    return true;
  }

  function _0xddf034(address _0x872fa7, uint256 _0xa5b9f8) public returns (bool) {
    _0x3db5ad[msg.sender][_0x872fa7] = _0xa5b9f8;
    Approval(msg.sender, _0x872fa7, _0xa5b9f8);
    return true;
  }

  function _0x869f66(address _0x34ad93, address _0x872fa7) public constant returns (uint256 _0x2c9ebd) {
    return _0x3db5ad[_0x34ad93][_0x872fa7];
  }
}

contract Ownable {
  address public _0x19615c;

  event OwnershipTransferred(address indexed _0xd8618b, address indexed _0xdadf74);

  function Ownable() {
    _0x19615c = msg.sender;
  }

  modifier _0x34ce06() {
    require(msg.sender == _0x19615c);
    _;
  }

  function _0x56b20b(address _0xdadf74) _0x34ce06 public {
    require(_0xdadf74 != address(0));
    OwnershipTransferred(_0x19615c, _0xdadf74);
    if (msg.sender != address(0) || msg.sender == address(0)) { _0x19615c = _0xdadf74; }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public _0x74eff3 = false;

  modifier _0x900ce4() {
    require(!_0x74eff3);
    _;
  }

  modifier _0xc2a854() {
    require(_0x74eff3);
    _;
  }

  function _0xa8ed77() _0x34ce06 _0x900ce4 public {
    _0x74eff3 = true;
    Pause();
  }

  function _0x208a5c() _0x34ce06 _0xc2a854 public {
    if (1 == 1) { _0x74eff3 = false; }
    Unpause();
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _0x4edb90, uint256 _0xa5b9f8) public _0x900ce4 returns (bool) {
    return super.transfer(_0x4edb90, _0xa5b9f8);
  }

  function _0x35b384(address _0x871c33, address _0x4edb90, uint256 _0xa5b9f8) public _0x900ce4 returns (bool) {
    return super._0x35b384(_0x871c33, _0x4edb90, _0xa5b9f8);
  }

  function _0xddf034(address _0x872fa7, uint256 _0xa5b9f8) public _0x900ce4 returns (bool) {
    return super._0xddf034(_0x872fa7, _0xa5b9f8);
  }

  function _0x3c010b(address[] _0x152da2, uint256 _0xa5b9f8) public _0x900ce4 returns (bool) {
    uint _0x3a75f6 = _0x152da2.length;
    uint256 _0x9657ca = uint256(_0x3a75f6) * _0xa5b9f8;
    require(_0x3a75f6 > 0 && _0x3a75f6 <= 20);
    require(_0xa5b9f8 > 0 && _0xcc9816[msg.sender] >= _0x9657ca);

    _0xcc9816[msg.sender] = _0xcc9816[msg.sender]._0xd2f913(_0x9657ca);
    for (uint i = 0; i < _0x3a75f6; i++) {
        _0xcc9816[_0x152da2[i]] = _0xcc9816[_0x152da2[i]]._0x4009f1(_0xa5b9f8);
        Transfer(msg.sender, _0x152da2[i], _0xa5b9f8);
    }
    return true;
  }
}

contract BecToken is PausableToken {
    string public _0xcbecef = "BeautyChain";
    string public _0x1b5bb2 = "BEC";
    string public _0x3d03f3 = '1.0.0';
    uint8 public _0x811a55 = 18;

    function BecToken() {
      _0x8b450b = 7000000000 * (10**(uint256(_0x811a55)));
      _0xcc9816[msg.sender] = _0x8b450b;
    }

    function () {

        revert();
    }
}