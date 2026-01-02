// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    PriceCalculatorA CalculatorAContract;
    PriceCalculatorB CalculatorBContract;

    function testCalculation() public {
        CalculatorAContract = new PriceCalculatorA();
        console.log("Perform Calculator A Contract");
        console.log(
            "Scenario: DeFi store 10% off now, Then we buy 1 item price: $80."
        );
        console.log(
            "Subtract the discount, get the sale price:",
            CalculatorAContract.price(80, 90)
        );
        console.log(
            "---------------------------------------------------------"
        );
        CalculatorBContract = new PriceCalculatorB();
        console.log("Perform Calculator B Contract");
        console.log(
            "Scenario: DeFi store 10% off now, Then we buy 1 item price: $80."
        );
        console.log(
            "Subtract  the discount, get the sale price:",
            CalculatorBContract.price(80, 90)
        );
    }
}

contract PriceCalculatorA {
    function price(
        uint256 price,
        uint256 discount
    ) public pure returns (uint256) {
        return (price / 100) * discount;
    }
}

contract PriceCalculatorB {
    function price(
        uint256 price,
        uint256 discount
    ) public pure returns (uint256) {
        return (price * discount) / 100;
    }
}