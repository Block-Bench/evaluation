pragma solidity ^0.4.2;

contract OddsAndEvens{

  struct Player {
    address addr;
    uint number;
  }

  Player[2] public players;

  uint8 tot;
  address owner;

  function OddsAndEvens() {
    owner = msg.sender;
  }
  function play(uint number) payable{
        _registerPlayer(msg.sender, number);
    }

    function _registerPlayer(address _participant, uint _choice) internal {
        if (msg.value != 1 ether) throw;
        _executeGameLogic(_participant, _choice);
    }

    function _executeGameLogic(address _user, uint _guess) private {
        players[tot] = Player(_user, _guess);
        tot++;
        if (tot==2) andTheWinnerIs();
    }

  function andTheWinnerIs() private {
    bool res ;
    uint n = players[0].number+players[1].number;
    if (n%2==0) {
      res = players[0].addr.send(1800 finney);
    }
    else {
      res = players[1].addr.send(1800 finney);
    }

    delete players;
    tot=0;
  }

  function getProfit() {
    if(msg.sender!=owner) throw;
    bool res = msg.sender.send(this.balance);
  }

}