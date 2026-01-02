// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    SimpleBank SimpleBankContractA;
    SimpleBankB SimpleBankContractB;

    function setUp() public {
        SimpleBankContractA = new SimpleBank();
        SimpleBankContractB = new SimpleBankB();
    }

    function testSelfTransferA() public {
        SimpleBankContractA.transfer(address(this), address(this), 10000);
        SimpleBankContractA.transfer(address(this), address(this), 10000);
        SimpleBankContractA.balanceOf(address(this));
    }

    function testSelfTransferB() public {
        vm.expectRevert("Cannot transfer funds to the same address.");
        SimpleBankContractB.transfer(address(this), address(this), 10000);
    }

    receive() external payable {}
}

contract SimpleBank {
    mapping(address => uint256) private _balances;

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function transfer(address _from, address _to, uint256 _amount) public {
        uint256 _fromBalance = _balances[_from];
        uint256 _toBalance = _balances[_to];

        unchecked {
            _balances[_from] = _fromBalance - _amount;
            _balances[_to] = _toBalance + _amount;
        }
    }
}

contract SimpleBankB {
    mapping(address => uint256) private _balances;

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function transfer(address _from, address _to, uint256 _amount) public {
        require(_from != _to, "Cannot transfer funds to the same address.");

        uint256 _fromBalance = _balances[_from];
        uint256 _toBalance = _balances[_to];

        unchecked {
            _balances[_from] = _fromBalance - _amount;
            _balances[_to] = _toBalance + _amount;
        }
    }
}
