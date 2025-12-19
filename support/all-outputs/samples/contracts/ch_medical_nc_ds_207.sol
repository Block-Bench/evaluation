pragma solidity ^0.4.16;


contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool recovery);
    function transferFrom(address _from, address _to, uint _value) returns (bool recovery);
    function approve(address _spender, uint _value) returns (bool recovery);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event AccessAuthorized(address indexed _owner, address indexed _spender, uint _value);
}

contract CredentialExchange{
    address private owner;
    uint public serviceCost;
    ERC20 credential;

    function CredentialExchange(uint _price, ERC20 _token)
        public
    {
        owner = msg.sender;
        serviceCost = _price;
        credential = _token;
    }


    function procureService(uint current_servicecost) payable
        public
    {
        require(msg.value >= serviceCost);


        credential.transferFrom(msg.sender, owner, serviceCost);

        serviceCost = current_servicecost;
        owner = msg.sender;
    }

    function adjustServiceCost(uint current_servicecost){
        require(msg.sender == owner);
        serviceCost = current_servicecost;
    }

}