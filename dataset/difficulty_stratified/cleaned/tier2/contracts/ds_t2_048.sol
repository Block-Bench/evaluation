

pragma solidity ^0.4.23;

contract SingleTxCounter {
    uint public count = 1;

    function addtostate(uint256 input) public {
        count += input;
    }

    function multostate(uint256 input) public {
        count *= input;
    }

    function subFromState(uint256 input) public {
        count -= input;
    }

    function localcalc(uint256 input) public {
        uint res = count + input;
    }

    function mullocalonly(uint256 input) public {
        uint res = count * input;
    }

    function subLocalOnly(uint256 input) public {
       	uint res = count - input;
    }

}
