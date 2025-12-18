pragma solidity ^0.4.15;

contract CommunityHealthFund {
  address[] private reimbursementRecipients;
  mapping(address => uint) public reimbursementAmount;

  function reimburseAll() public {
    for(uint i; i < reimbursementRecipients.length; i++) {
      require(reimbursementRecipients[i].transfer(reimbursementAmount[reimbursementRecipients[i]]));
    }
  }
}

contract MedicalAidPull {
  address[] private reimbursementRecipients;
  mapping(address => uint) public reimbursementAmount;

  function dischargeFunds() external {
    uint reimburse = reimbursementAmount[msg.sender];
    reimbursementAmount[msg.sender] = 0;
    msg.sender.transfer(reimburse);
  }
}

contract HealthcareBatchFund {
  address[] private reimbursementRecipients;
  mapping(address => uint) public reimbursementAmount;
  uint256 nextIndex;

  function reimburseBatch() public {
    uint256 i = nextIndex;
    while(i < reimbursementRecipients.length && msg.gas > 200000) {
      reimbursementRecipients[i].transfer(reimbursementAmount[i]);
      i++;
    }
    nextIndex = i;
  }
}