pragma solidity ^0.4.15;

contract CrowdFundBasic {
  address[] private refundAddresses;
  mapping(address => uint) public refundAmount;

  function refundAll() public {
    for(uint i; i < refundAddresses.length; i++) {
      require(refundAddresses[i].transfer(refundAmount[refundAddresses[i]]));
    }
  }
}

contract CrowdFundPull {
  address[] private refundAddresses;
  mapping(address => uint) public refundAmount;

  function withdraw() external {
    uint refund = refundAmount[msg.sender];
    refundAmount[msg.sender] = 0;
    msg.sender.transfer(refund);
  }
}

contract CrowdFundBatched {
  address[] private refundAddresses;
  mapping(address => uint) public refundAmount;
  uint256 nextIdx;

  function refundBatched() public {
    uint256 i = nextIdx;
    while(i < refundAddresses.length && msg.gas > 200000) {
      refundAddresses[i].transfer(refundAmount[i]);
      i++;
    }
    nextIdx = i;
  }
}