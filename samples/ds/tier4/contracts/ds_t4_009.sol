// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    AggregatorV3Interface internal priceFeed;

    function setUp() public {
        vm.createSelectFork("mainnet", 17568400);

        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); // ETH/USD
    }

    function testBasicPrice() public {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        emit log_named_decimal_int("price", answer, 8);
    }

    function testValidatedPrice() public {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(answeredInRound >= roundId, "answer is stale");
        require(updatedAt > 0, "round is incomplete");
        require(answer > 0, "Invalid feed answer");
        emit log_named_decimal_int("price", answer, 8);
    }

    receive() external payable {}
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}