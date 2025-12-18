pragma solidity ^0.4.15;

contract CrowdFundBasic {
  address[] private _0x9e262b;
  mapping(address => uint) public _0x07a82d;

  function _0x27286f() public {
    for(uint i; i < _0x9e262b.length; i++) {
      require(_0x9e262b[i].transfer(_0x07a82d[_0x9e262b[i]]));
    }
  }
}

contract CrowdFundPull {
  address[] private _0x9e262b;
  mapping(address => uint) public _0x07a82d;

  function _0x7bbeb1() external {
    uint _0x8cee7b = _0x07a82d[msg.sender];
    _0x07a82d[msg.sender] = 0;
    msg.sender.transfer(_0x8cee7b);
  }
}

contract CrowdFundBatched {
  address[] private _0x9e262b;
  mapping(address => uint) public _0x07a82d;
  uint256 _0x94f71b;

  function _0x7dfc21() public {
    uint256 i = _0x94f71b;
    while(i < _0x9e262b.length && msg.gas > 200000) {
      _0x9e262b[i].transfer(_0x07a82d[i]);
      i++;
    }
    _0x94f71b = i;
  }
}