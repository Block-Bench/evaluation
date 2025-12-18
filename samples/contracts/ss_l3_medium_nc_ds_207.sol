pragma solidity ^0.4.16;


contract ERC20 {
    function _0xe38227() constant returns (uint _0xe38227);
    function _0x44a115(address _0x8e27c6) constant returns (uint balance);
    function transfer(address _0x44d6b0, uint _0xaf5fa2) returns (bool _0x9198b2);
    function _0x28e97d(address _0xfbd9a2, address _0x44d6b0, uint _0xaf5fa2) returns (bool _0x9198b2);
    function _0x3eb377(address _0x27cfc9, uint _0xaf5fa2) returns (bool _0x9198b2);
    function _0x966460(address _0x8e27c6, address _0x27cfc9) constant returns (uint _0xd0e99a);
    event Transfer(address indexed _0xfbd9a2, address indexed _0x44d6b0, uint _0xaf5fa2);
    event Approval(address indexed _0x8e27c6, address indexed _0x27cfc9, uint _0xaf5fa2);
}

contract TokenExchange{
    address private _0xc42d56;
    uint public _0xa9687f;
    ERC20 _0x83275e;

    function TokenExchange(uint _0xf6691a, ERC20 _0xa46d7f)
        public
    {
        _0xc42d56 = msg.sender;
        _0xa9687f = _0xf6691a;
        _0x83275e = _0xa46d7f;
    }


    function _0xca3f3d(uint _0x4a55d2) payable
        public
    {
        require(msg.value >= _0xa9687f);


        _0x83275e._0x28e97d(msg.sender, _0xc42d56, _0xa9687f);

        _0xa9687f = _0x4a55d2;
        _0xc42d56 = msg.sender;
    }

    function _0x9215c8(uint _0x4a55d2){
        require(msg.sender == _0xc42d56);
        _0xa9687f = _0x4a55d2;
    }

}