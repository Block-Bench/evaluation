pragma solidity ^0.4.13;

library SafeMath {
  function _0x4c90cc(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function _0x463c7f(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint public _0x8ca55e;
  address public _0xc56dc9;
  address public _0x3ebb9d;
  function _0x74a8c1(address _0xe69c00) constant returns (uint);
  function transfer(address _0xbb0b77, uint value);
  event Transfer(address indexed from, address indexed _0xbb0b77, uint value);
  function _0x701abe(address _0xe69c00) internal;
}

contract ERC20 is ERC20Basic {
  function _0xc9a00b(address _0xc56dc9, address _0x89c8a6) constant returns (uint);
  function _0x863384(address from, address _0xbb0b77, uint value);
  function _0xb2fe84(address _0x89c8a6, uint value);
  event Approval(address indexed _0xc56dc9, address indexed _0x89c8a6, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) _0xc92889;

  modifier _0x1849dc(uint _0x15f408) {
     assert(msg.data.length >= _0x15f408 + 4);
     _;
  }

  function transfer(address _0x9afef8, uint _0xc3a17e) _0x1849dc(2 * 32) {
    _0x701abe(msg.sender);
    _0xc92889[msg.sender] = _0xc92889[msg.sender]._0x4c90cc(_0xc3a17e);
    if(_0x9afef8 == address(this)) {
        _0x701abe(_0xc56dc9);
        _0xc92889[_0xc56dc9] = _0xc92889[_0xc56dc9]._0x463c7f(_0xc3a17e);
        Transfer(msg.sender, _0xc56dc9, _0xc3a17e);
    }
    else {
        _0x701abe(_0x9afef8);
        _0xc92889[_0x9afef8] = _0xc92889[_0x9afef8]._0x463c7f(_0xc3a17e);
        Transfer(msg.sender, _0x9afef8, _0xc3a17e);
    }
  }

  function _0x74a8c1(address _0x0e1382) constant returns (uint balance) {
    return _0xc92889[_0x0e1382];
  }
}

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) _0x419b65;

  function _0x863384(address _0x3a72c6, address _0x9afef8, uint _0xc3a17e) _0x1849dc(3 * 32) {
    var _0x95317d = _0x419b65[_0x3a72c6][msg.sender];
    _0x701abe(_0x3a72c6);
    _0x701abe(_0x9afef8);
    _0xc92889[_0x9afef8] = _0xc92889[_0x9afef8]._0x463c7f(_0xc3a17e);
    _0xc92889[_0x3a72c6] = _0xc92889[_0x3a72c6]._0x4c90cc(_0xc3a17e);
    _0x419b65[_0x3a72c6][msg.sender] = _0x95317d._0x4c90cc(_0xc3a17e);
    Transfer(_0x3a72c6, _0x9afef8, _0xc3a17e);
  }

  function _0xb2fe84(address _0xfd5860, uint _0xc3a17e) {

    assert(!((_0xc3a17e != 0) && (_0x419b65[msg.sender][_0xfd5860] != 0)));
    _0x419b65[msg.sender][_0xfd5860] = _0xc3a17e;
    Approval(msg.sender, _0xfd5860, _0xc3a17e);
  }

  function _0xc9a00b(address _0x0e1382, address _0xfd5860) constant returns (uint _0xc3d6a6) {
    return _0x419b65[_0x0e1382][_0xfd5860];
  }
}

contract SmartBillions is StandardToken {


    string public constant _0x54bdba = "SmartBillions Token";
    string public constant _0xc65f9c = "PLAY";
    uint public constant _0x2260f4 = 0;


    struct Wallet {
        uint208 balance;
    	uint16 _0x6fd30a;
    	uint32 _0x0cbaf1;
    }
    mapping (address => Wallet) _0x736d87;
    struct Bet {
        uint192 value;
        uint32 _0xbe6a97;
        uint32 _0xfb1754;
    }
    mapping (address => Bet) _0x530027;

    uint public _0x69deca = 0;


    uint public _0xf01a29 = 1;
    uint public _0x858161 = 0;
    uint public _0x056d1f = 200000 ether;
    uint public _0x3ca55b = 1;
    uint[] public _0xa35ab4;


    uint public _0x1d18a6 = 0;
    uint public _0x72c28a = 0;
    uint public _0xa4915c = 0;
    uint public _0xdb2887 = 0;
    uint public _0xc44c95 = 0;
    uint public _0x0cadf5 = 5 ether;
    uint[] public _0x6dd5da;


    uint public constant _0x3aced4 = 16384 ;
    uint public _0x8263cd = 0 ;


    event LogBet(address indexed _0xab2139, uint _0x197125, uint _0xd86512, uint _0xd33697);
    event LogLoss(address indexed _0xab2139, uint _0x197125, uint _0x4e0c86);
    event LogWin(address indexed _0xab2139, uint _0x197125, uint _0x4e0c86, uint _0x34e8a8);
    event LogInvestment(address indexed _0x622eff, address indexed _0x8ab0cc, uint _0x3ea4b7);
    event LogRecordWin(address indexed _0xab2139, uint _0x3ea4b7);
    event LogLate(address indexed _0xab2139,uint _0x310fc2,uint _0xd7140b);
    event LogDividend(address indexed _0x622eff, uint _0x3ea4b7, uint _0xc169d6);

    modifier _0x513abd() {
        assert(msg.sender == _0xc56dc9);
        _;
    }

    modifier _0x26700d() {
        assert(msg.sender == _0x3ebb9d);
        _;
    }


    function SmartBillions() {
        _0xc56dc9 = msg.sender;
        _0x3ebb9d = msg.sender;
        _0x736d87[_0xc56dc9]._0x6fd30a = uint16(_0x3ca55b);
        _0xa35ab4.push(0);
        _0xa35ab4.push(0);
    }


    function _0xd4b29f() constant external returns (uint) {
        return uint(_0x6dd5da.length);
    }

    function _0x38790f(address _0x0e1382) constant external returns (uint) {
        return uint(_0x736d87[_0x0e1382].balance);
    }

    function _0xcb0eb4(address _0x0e1382) constant external returns (uint) {
        return uint(_0x736d87[_0x0e1382]._0x6fd30a);
    }

    function _0x3cd1f2(address _0x0e1382) constant external returns (uint) {
        return uint(_0x736d87[_0x0e1382]._0x0cbaf1);
    }

    function _0x21e8b8(address _0x0e1382) constant external returns (uint) {
        return uint(_0x530027[_0x0e1382].value);
    }

    function _0x917ffa(address _0x0e1382) constant external returns (uint) {
        return uint(_0x530027[_0x0e1382]._0xbe6a97);
    }

    function _0x68dcf0(address _0x0e1382) constant external returns (uint) {
        return uint(_0x530027[_0x0e1382]._0xfb1754);
    }

    function _0x1b8848() constant external returns (uint) {
        if(_0xf01a29 > 0) {
            return(0);
        }
        uint _0xc169d6 = (block.number - _0x72c28a) / (10 * _0x3aced4);
        if(_0xc169d6 > _0x3ca55b) {
            return(0);
        }
        return((10 * _0x3aced4) - ((block.number - _0x72c28a) % (10 * _0x3aced4)));
    }


    function _0x5b9323(address _0x23548b) external _0x513abd {
        assert(_0x23548b != address(0));
        _0x701abe(msg.sender);
        _0x701abe(_0x23548b);
        if (gasleft() > 0) { _0xc56dc9 = _0x23548b; }
    }

    function _0xe895e2(address _0x23548b) external _0x26700d {
        assert(_0x23548b != address(0));
        _0x701abe(msg.sender);
        _0x701abe(_0x23548b);
        _0x3ebb9d = _0x23548b;
    }

    function _0x6e63df(uint _0x776c77) external _0x513abd {
        require(_0xf01a29 == 1 && _0x72c28a > 0 && block.number < _0x776c77);
        if (block.timestamp > 0) { _0xf01a29 = _0x776c77; }
    }

    function _0x386aec(uint _0xbb6eef) external _0x513abd {
        _0x0cadf5 = _0xbb6eef;
    }

    function _0x024ce2() external _0x513abd {
        if (true) { _0xdb2887 = block.number + 3; }
        if (msg.sender != address(0) || msg.sender == address(0)) { _0xc44c95 = 0; }
    }

    function _0x96878c(uint _0xc53a6b) external _0x513abd {
        _0xa38b3e();
        require(_0xc53a6b > 0 && this.balance >= (_0x858161 * 9 / 10) + _0x69deca + _0xc53a6b);
        if(_0x858161 >= _0x056d1f / 2){
            require((_0xc53a6b <= this.balance / 400) && _0x8263cd + 4 * 60 * 24 * 7 <= block.number);
        }
        msg.sender.transfer(_0xc53a6b);
        _0x8263cd = block.number;
    }

    function _0xb19196() payable external {
        _0xa38b3e();
    }


    function _0xa38b3e() public {
        if(_0xf01a29 > 1 && block.number >= _0xf01a29 + (_0x3aced4 * 5)){
            if (1 == 1) { _0xf01a29 = 0; }
        }
        else {
            if(_0x72c28a > 0){
		        uint _0xc169d6 = (block.number - _0x72c28a) / (10 * _0x3aced4 );
                if(_0xc169d6 > _0xa35ab4.length - 2) {
                    _0xa35ab4.push(0);
                }
                if(_0xc169d6 > _0x3ca55b && _0xf01a29 == 0 && _0x3ca55b < _0xa35ab4.length - 1) {
                    _0x3ca55b++;
                }
            }
        }
    }


    function _0x584258() public {
        if(_0x736d87[msg.sender].balance > 0 && _0x736d87[msg.sender]._0x0cbaf1 <= block.number){
            uint balance = _0x736d87[msg.sender].balance;
            _0x736d87[msg.sender].balance = 0;
            _0x69deca -= balance;
            _0x2a2cb6(balance);
        }
    }

    function _0x2a2cb6(uint _0xc53a6b) private {
        uint _0x7b63fc = this.balance / 2;
        if(_0x7b63fc >= _0xc53a6b) {
            msg.sender.transfer(_0xc53a6b);
            if(_0xc53a6b > 1 finney) {
                _0xa38b3e();
            }
        }
        else {
            uint _0x4ec658 = _0xc53a6b - _0x7b63fc;
            _0x69deca += _0x4ec658;
            _0x736d87[msg.sender].balance += uint208(_0x4ec658);
            _0x736d87[msg.sender]._0x0cbaf1 = uint32(block.number + 4 * 60 * 24 * 30);
            msg.sender.transfer(_0x7b63fc);
        }
    }


    function _0x3ad813() payable external {
        _0x38525f(_0xc56dc9);
    }

    function _0x38525f(address _0x77dd63) payable public {

        require(_0xf01a29 > 1 && block.number < _0xf01a29 + (_0x3aced4 * 5) && _0x858161 < _0x056d1f);
        uint _0xfde001 = msg.value;
        if(_0xfde001 > _0x056d1f - _0x858161) {
            _0xfde001 = _0x056d1f - _0x858161;
            if (gasleft() > 0) { _0x858161 = _0x056d1f; }
            _0xf01a29 = 0;
            msg.sender.transfer(msg.value._0x4c90cc(_0xfde001));
        }
        else{
            _0x858161 += _0xfde001;
        }
        if(_0x77dd63 == address(0) || _0x77dd63 == _0xc56dc9){
            _0x69deca += _0xfde001 / 10;
            _0x736d87[_0xc56dc9].balance += uint208(_0xfde001 / 10);}
        else{
            _0x69deca += (_0xfde001 * 5 / 100) * 2;
            _0x736d87[_0xc56dc9].balance += uint208(_0xfde001 * 5 / 100);
            _0x736d87[_0x77dd63].balance += uint208(_0xfde001 * 5 / 100);}
        _0x736d87[msg.sender]._0x6fd30a = uint16(_0x3ca55b);
        uint _0xf2a1f9 = _0xfde001 / 10**15;
        uint _0x2dc868 = _0xfde001 * 16 / 10**17  ;
        uint _0xd3d740 = _0xfde001 * 10 / 10**17  ;
        _0xc92889[msg.sender] += _0xf2a1f9;
        _0xc92889[_0xc56dc9] += _0x2dc868 ;
        _0xc92889[_0x3ebb9d] += _0xd3d740 ;
        _0x8ca55e += _0xf2a1f9 + _0x2dc868 + _0xd3d740;
        Transfer(address(0),msg.sender,_0xf2a1f9);
        Transfer(address(0),_0xc56dc9,_0x2dc868);
        Transfer(address(0),_0x3ebb9d,_0xd3d740);
        LogInvestment(msg.sender,_0x77dd63,_0xfde001);
    }

    function _0xbce26d() external {
        require(_0xf01a29 == 0);
        _0x701abe(msg.sender);
        uint _0x51b7b7 = _0xc92889[msg.sender] * 10**15;
        Transfer(msg.sender,address(0),_0xc92889[msg.sender]);
        delete _0xc92889[msg.sender];
        _0x858161 -= _0x51b7b7;
        _0x736d87[msg.sender].balance += uint208(_0x51b7b7 * 9 / 10);
        _0x584258();
    }

    function _0x0b263e() external {
        require(_0xf01a29 == 0);
        _0x701abe(msg.sender);
        _0x584258();
    }

    function _0x701abe(address _0x23548b) internal {
        uint _0x28ca64 = _0x736d87[_0x23548b]._0x6fd30a;
        if((_0xc92889[_0x23548b]==0) || (_0x28ca64==0)){
            _0x736d87[_0x23548b]._0x6fd30a=uint16(_0x3ca55b);
            return;
        }
        if(_0x28ca64==_0x3ca55b) {
            return;
        }
        uint _0xad23ca = _0xc92889[_0x23548b] * 0xffffffff / _0x8ca55e;
        uint balance = 0;
        for(;_0x28ca64<_0x3ca55b;_0x28ca64++) {
            balance += _0xad23ca * _0xa35ab4[_0x28ca64];
        }
        balance = (balance / 0xffffffff);
        _0x69deca += balance;
        _0x736d87[_0x23548b].balance += uint208(balance);
        _0x736d87[_0x23548b]._0x6fd30a = uint16(_0x28ca64);
        LogDividend(_0x23548b,balance,_0x28ca64);
    }


    function _0xa37364(Bet _0x8fec04, uint24 _0x9b9af3) constant private returns (uint) {
        uint24 _0x197125 = uint24(_0x8fec04._0xbe6a97);
        uint24 _0x5ecba0 = _0x197125 ^ _0x9b9af3;
        uint24 _0xf020c8 =
            ((_0x5ecba0 & 0xF) == 0 ? 1 : 0 ) +
            ((_0x5ecba0 & 0xF0) == 0 ? 1 : 0 ) +
            ((_0x5ecba0 & 0xF00) == 0 ? 1 : 0 ) +
            ((_0x5ecba0 & 0xF000) == 0 ? 1 : 0 ) +
            ((_0x5ecba0 & 0xF0000) == 0 ? 1 : 0 ) +
            ((_0x5ecba0 & 0xF00000) == 0 ? 1 : 0 );
        if(_0xf020c8 == 6){
            return(uint(_0x8fec04.value) * 7000000);
        }
        if(_0xf020c8 == 5){
            return(uint(_0x8fec04.value) * 20000);
        }
        if(_0xf020c8 == 4){
            return(uint(_0x8fec04.value) * 500);
        }
        if(_0xf020c8 == 3){
            return(uint(_0x8fec04.value) * 25);
        }
        if(_0xf020c8 == 2){
            return(uint(_0x8fec04.value) * 3);
        }
        return(0);
    }

    function _0xbf5a80(address _0x23548b) constant external returns (uint)  {
        Bet memory _0xab2139 = _0x530027[_0x23548b];
        if( (_0xab2139.value==0) ||
            (_0xab2139._0xfb1754<=1) ||
            (block.number<_0xab2139._0xfb1754) ||
            (block.number>=_0xab2139._0xfb1754 + (10 * _0x3aced4))){
            return(0);
        }
        if(block.number<_0xab2139._0xfb1754+256){
            return(_0xa37364(_0xab2139,uint24(block.blockhash(_0xab2139._0xfb1754))));
        }
        if(_0x72c28a>0){
            uint32 _0x4e0c86 = _0x44ec67(_0xab2139._0xfb1754);
            if(_0x4e0c86 == 0x1000000) {
                return(uint(_0xab2139.value));
            }
            else{
                return(_0xa37364(_0xab2139,uint24(_0x4e0c86)));
            }
	}
        return(0);
    }

    function _0x51b518() public {
        Bet memory _0xab2139 = _0x530027[msg.sender];
        if(_0xab2139._0xfb1754==0){
            _0x530027[msg.sender] = Bet({value: 0, _0xbe6a97: 0, _0xfb1754: 1});
            return;
        }
        if((_0xab2139.value==0) || (_0xab2139._0xfb1754==1)){
            _0x584258();
            return;
        }
        require(block.number>_0xab2139._0xfb1754);
        if(_0xab2139._0xfb1754 + (10 * _0x3aced4) <= block.number){
            LogLate(msg.sender,_0xab2139._0xfb1754,block.number);
            _0x530027[msg.sender] = Bet({value: 0, _0xbe6a97: 0, _0xfb1754: 1});
            return;
        }
        uint _0x34e8a8 = 0;
        uint32 _0x4e0c86 = 0;
        if(block.number<_0xab2139._0xfb1754+256){
            _0x4e0c86 = uint24(block.blockhash(_0xab2139._0xfb1754));
            if (gasleft() > 0) { _0x34e8a8 = _0xa37364(_0xab2139,uint24(_0x4e0c86)); }
        }
        else {
            if(_0x72c28a>0){
                _0x4e0c86 = _0x44ec67(_0xab2139._0xfb1754);
                if(_0x4e0c86 == 0x1000000) {
                    _0x34e8a8 = uint(_0xab2139.value);
                }
                else{
                    _0x34e8a8 = _0xa37364(_0xab2139,uint24(_0x4e0c86));
                }
	    }
            else{
                LogLate(msg.sender,_0xab2139._0xfb1754,block.number);
                _0x530027[msg.sender] = Bet({value: 0, _0xbe6a97: 0, _0xfb1754: 1});
                return();
            }
        }
        _0x530027[msg.sender] = Bet({value: 0, _0xbe6a97: 0, _0xfb1754: 1});
        if(_0x34e8a8>0) {
            LogWin(msg.sender,uint(_0xab2139._0xbe6a97),uint(_0x4e0c86),_0x34e8a8);
            if(_0x34e8a8 > _0x1d18a6){
                _0x1d18a6 = _0x34e8a8;
                LogRecordWin(msg.sender,_0x34e8a8);
            }
            _0x2a2cb6(_0x34e8a8);
        }
        else{
            LogLoss(msg.sender,uint(_0xab2139._0xbe6a97),uint(_0x4e0c86));
        }
    }

    function () payable external {
        if(msg.value > 0){
            if(_0xf01a29>1){
                _0x38525f(_0xc56dc9);
            }
            else{
                _0xe57234();
            }
            return;
        }

        if(_0xf01a29 == 0 && _0xc92889[msg.sender]>0){
            _0x701abe(msg.sender);}
        _0x51b518();
    }

    function _0xe57234() payable public returns (uint) {
        return _0xbac12b(uint(_0x9afad8(msg.sender,block.number)), address(0));
    }

    function _0x71e9f2(address _0x77dd63) payable public returns (uint) {
        return _0xbac12b(uint(_0x9afad8(msg.sender,block.number)), _0x77dd63);
    }

    function _0xbac12b(uint _0x9b9af3, address _0x77dd63) payable public returns (uint) {
        _0x51b518();
        uint24 _0x197125 = uint24(_0x9b9af3);
        require(msg.value <= 1 ether && msg.value < _0x0cadf5);
        if(msg.value > 0){
            if(_0xf01a29==0) {
                _0xa35ab4[_0x3ca55b] += msg.value / 20;
            }
            if(_0x77dd63 != address(0)) {
                uint _0xefa277 = msg.value / 100;
                _0x69deca += _0xefa277;
                _0x736d87[_0x77dd63].balance += uint208(_0xefa277);
            }
            if(_0xdb2887 < block.number + 3) {
                _0xdb2887 = block.number + 3;
                _0xc44c95 = msg.value;
            }
            else{
                if(_0xc44c95 > _0x0cadf5) {
                    _0xdb2887++;
                    if (msg.sender != address(0) || msg.sender == address(0)) { _0xc44c95 = msg.value; }
                }
                else{
                    _0xc44c95 += msg.value;
                }
            }
            _0x530027[msg.sender] = Bet({value: uint192(msg.value), _0xbe6a97: uint32(_0x197125), _0xfb1754: uint32(_0xdb2887)});
            LogBet(msg.sender,uint(_0x197125),_0xdb2887,msg.value);
        }
        _0xc22e5a();
        return(_0xdb2887);
    }


    function _0x9a8c0e(uint _0xf8c123) public returns (uint) {
        require(_0x72c28a == 0 && _0xf8c123 > 0 && _0xf8c123 <= _0x3aced4);
        uint n = _0x6dd5da.length;
        if(n + _0xf8c123 > _0x3aced4){
            _0x6dd5da.length = _0x3aced4;
        }
        else{
            _0x6dd5da.length += _0xf8c123;
        }
        for(;n<_0x6dd5da.length;n++){
            _0x6dd5da[n] = 1;
        }
        if(_0x6dd5da.length>=_0x3aced4) {
            _0x72c28a = block.number - ( block.number % 10);
            _0xa4915c = _0x72c28a;
        }
        return(_0x6dd5da.length);
    }

    function _0xefdedf() external returns (uint) {
        return(_0x9a8c0e(128));
    }

    function _0xa2e5fe(uint32 _0x0439be, uint32 _0x67e34d) constant private returns (uint) {
        return( ( uint(block.blockhash(_0x0439be  )) & 0xFFFFFF )
            | ( ( uint(block.blockhash(_0x0439be+1)) & 0xFFFFFF ) << 24 )
            | ( ( uint(block.blockhash(_0x0439be+2)) & 0xFFFFFF ) << 48 )
            | ( ( uint(block.blockhash(_0x0439be+3)) & 0xFFFFFF ) << 72 )
            | ( ( uint(block.blockhash(_0x0439be+4)) & 0xFFFFFF ) << 96 )
            | ( ( uint(block.blockhash(_0x0439be+5)) & 0xFFFFFF ) << 120 )
            | ( ( uint(block.blockhash(_0x0439be+6)) & 0xFFFFFF ) << 144 )
            | ( ( uint(block.blockhash(_0x0439be+7)) & 0xFFFFFF ) << 168 )
            | ( ( uint(block.blockhash(_0x0439be+8)) & 0xFFFFFF ) << 192 )
            | ( ( uint(block.blockhash(_0x0439be+9)) & 0xFFFFFF ) << 216 )
            | ( ( uint(_0x67e34d) / _0x3aced4) << 240));
    }

    function _0x44ec67(uint _0x25f12c) constant private returns (uint32) {
        uint _0x541fae = (_0x25f12c - _0x72c28a) / 10;
        uint _0x4e0c86 = _0x6dd5da[_0x541fae % _0x3aced4];
        if(_0x541fae / _0x3aced4 != _0x4e0c86 >> 240) {
            return(0x1000000);
        }
        uint _0x0d9cc1 = (_0x25f12c - _0x72c28a) % 10;
        return(uint32((_0x4e0c86 >> (24 * _0x0d9cc1)) & 0xFFFFFF));
    }

    function _0xc22e5a() public returns (bool) {
        uint _0xb07fac = _0xa4915c;
        if(_0xb07fac == 0 || block.number <= _0xb07fac + 10) {
            return(false);
        }
        uint _0x083737;
        if(block.number<256) {
            _0x083737 = 0;
        }
        else{
            _0x083737 = block.number - 256;
        }
        if(_0xb07fac < _0x083737) {
            uint _0xa57dc0 = _0x083737;
            _0xa57dc0 += _0xa57dc0 % 10;
            if (block.timestamp > 0) { _0xb07fac = _0xa57dc0; }
        }
        uint _0x541fae = (_0xb07fac - _0x72c28a) / 10;
        _0x6dd5da[_0x541fae % _0x3aced4] = _0xa2e5fe(uint32(_0xb07fac),uint32(_0x541fae));
        _0xa4915c = _0xb07fac + 10;
        return(true);
    }

    function _0x6a5a44(uint _0x617423) external {
        uint n=0;
        for(;n<_0x617423;n++){
            if(!_0xc22e5a()){
                return;
            }
        }
    }

}