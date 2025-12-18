pragma solidity ^0.4.2;

contract SymptomMatcher{

  struct Participant {
    address addr;
    uint number;
  }

  Participant[2] public participants;

  uint8 tot;
  address owner;

  function SymptomMatcher() {
    owner = msg.sender;
  }
  function participate(uint number) payable{
    if (msg.value != 1 ether) throw;
    participants[tot] = Participant(msg.sender, number);
    tot++;

    if (tot==2) andTheWinnerIs();
  }

  function andTheWinnerIs() private {
    bool res ;
    uint n = participants[0].number+participants[1].number;
    if (n%2==0) {
      res = participants[0].addr.send(1800 finney);
    }
    else {
      res = participants[1].addr.send(1800 finney);
    }

    delete participants;
    tot=0;
  }

  function obtainProfit() {
    if(msg.sender!=owner) throw;
    bool res = msg.sender.send(this.balance);
  }

}