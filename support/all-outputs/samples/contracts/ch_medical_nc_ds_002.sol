pragma solidity ^0.4.15;

contract PatientRecordsVault {
    mapping (address => uint) patientCredits;

    function retrieveCredits(address u) constant returns(uint){
        return patientCredits[u];
    }

    function creditAccount() payable{
        patientCredits[msg.sender] += msg.value;
    }

    function withdrawCredits(){


        if( ! (msg.sender.call.value(patientCredits[msg.sender])() ) ){
            throw;
        }
        patientCredits[msg.sender] = 0;
    }

    function dischargefundsAccountcreditsV2(){


        uint quantity = patientCredits[msg.sender];
        patientCredits[msg.sender] = 0;
        if( ! (msg.sender.call.value(quantity)() ) ){
            throw;
        }
    }

    function dischargefundsAccountcreditsV3(){


        msg.sender.transfer(patientCredits[msg.sender]);
        patientCredits[msg.sender] = 0;
    }

}