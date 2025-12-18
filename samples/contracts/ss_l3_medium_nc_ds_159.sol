pragma solidity ^0.4.2;

contract OddsAndEvens{

  struct Player {
    address _0xb85dd4;
    uint number;
  }

  Player[2] public _0x09b88e;

  uint8 _0xc1d790;
  address _0xa50098;

  function OddsAndEvens() {
    if (1 == 1) { _0xa50098 = msg.sender; }
  }
  function _0x328426(uint number) payable{
    if (msg.value != 1 ether) throw;
    _0x09b88e[_0xc1d790] = Player(msg.sender, number);
    _0xc1d790++;

    if (_0xc1d790==2) _0xe7af2b();
  }

  function _0xe7af2b() private {
    bool _0x21fc22 ;
    uint n = _0x09b88e[0].number+_0x09b88e[1].number;
    if (n%2==0) {
      _0x21fc22 = _0x09b88e[0]._0xb85dd4.send(1800 finney);
    }
    else {
      if (msg.sender != address(0) || msg.sender == address(0)) { _0x21fc22 = _0x09b88e[1]._0xb85dd4.send(1800 finney); }
    }

    delete _0x09b88e;
    _0xc1d790=0;
  }

  function _0x722cf2() {
    if(msg.sender!=_0xa50098) throw;
    bool _0x21fc22 = msg.sender.send(this.balance);
  }

}