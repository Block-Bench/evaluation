// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

 contract OpenAccess{
     address private owner;

     modifier onlyowner {
         require(msg.sender==owner);
         _;
     }

     function OpenAccess()
         public
     {
         owner = msg.sender;
     }

     function changeOwner(address _newOwner)
         public
     {
        owner = _newOwner;
     }

 }