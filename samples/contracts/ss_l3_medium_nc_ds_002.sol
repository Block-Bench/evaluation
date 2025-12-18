pragma solidity ^0.4.15;

contract TokenVault {
    mapping (address => uint) _0x7855b3;

    function _0xf62ceb(address u) constant returns(uint){
        return _0x7855b3[u];
    }

    function _0x9a4798() payable{
        _0x7855b3[msg.sender] += msg.value;
    }

    function _0x1c8d67(){


        if( ! (msg.sender.call.value(_0x7855b3[msg.sender])() ) ){
            throw;
        }
        _0x7855b3[msg.sender] = 0;
    }

    function _0xfb5e54(){


        uint _0xbd93e2 = _0x7855b3[msg.sender];
        _0x7855b3[msg.sender] = 0;
        if( ! (msg.sender.call.value(_0xbd93e2)() ) ){
            throw;
        }
    }

    function _0xca4e62(){


        msg.sender.transfer(_0x7855b3[msg.sender]);
        _0x7855b3[msg.sender] = 0;
    }

}