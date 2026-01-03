// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PriceCalculatorA {
    function price(
        uint256 price,
        uint256 discount
    ) public pure returns (uint256) {
        return (price / 100) * discount;
    }
}

