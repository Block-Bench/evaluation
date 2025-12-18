pragma solidity ^0.4.22;

contract FindThisHash {
    bytes32 constant public hash = 0xb5b5b97fafd9855eec9b41f74dfb6c38f5951141f9a3ecd7f44d5479b630ee0a;

    constructor() public payable {}

    function solve(string solution) public {
        _validateSolution(msg.sender, solution);
    }

    function _validateSolution(address _participant, string _answer) internal {
        require(hash == sha3(_answer));
        _processReward(_participant);
    }

    function _processReward(address _winner) private {
        _winner.transfer(1000 ether);
    }
}