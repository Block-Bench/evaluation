// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

contract SimpleAuction {
    address currentUser;
    uint currentBid;

    function bid() payable {
        require(msg.value > currentBid);

        if (currentUser != 0) {
            require(currentUser.send(currentBid));
        }

        currentUser = msg.sender;
        currentBid = msg.value;
    }
}
