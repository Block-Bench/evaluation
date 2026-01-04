pragma solidity ^0.4.0;

contract SimpleDestruct {
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}
