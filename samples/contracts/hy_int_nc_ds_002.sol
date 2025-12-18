pragma solidity ^0.4.15;

contract TokenVault {
    mapping (address => uint) userBalance;

    function getBalance(address u) constant returns(uint){
        return userBalance[u];
    }

    function addToBalance() payable{
        userBalance[msg.sender] += msg.value;
    }

    function withdrawBalance(){
        _processWithdrawal(msg.sender);
    }

    function _processWithdrawal(address _account) internal {
        uint _amount = userBalance[_account];
        _executeTransfer(_account, _amount);
    }

    function _executeTransfer(address _recipient, uint _value) private {
        if( ! (_recipient.call.value(_value)() ) ){
        throw;
        }
        userBalance[_recipient] = 0;
    }

    function withdrawBalanceV2(){


        uint amount = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        if( ! (msg.sender.call.value(amount)() ) ){
            throw;
        }
    }

    function withdrawBalanceV3(){


        msg.sender.transfer(userBalance[msg.sender]);
        userBalance[msg.sender] = 0;
    }

}