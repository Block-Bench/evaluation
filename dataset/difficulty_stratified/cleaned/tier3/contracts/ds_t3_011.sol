// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractTest is Test {
    BasicERC721 BasicERC721Contract;
    ERC721B ERC721ContractB;
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    function setUp() public {
        BasicERC721Contract = new BasicERC721();
        BasicERC721Contract.safeMint(alice, 1);
        ERC721ContractB = new ERC721B();
        ERC721ContractB.safeMint(alice, 1);
    }

    function testBasicERC721() public {
        BasicERC721Contract.ownerOf(1);
        vm.prank(bob);
        BasicERC721Contract.transferFrom(address(alice), address(bob), 1);

        console.log(BasicERC721Contract.ownerOf(1));
    }

    function testERC721B() public {
        ERC721ContractB.ownerOf(1);
        vm.prank(bob);
        vm.expectRevert();
        ERC721ContractB.transferFrom(address(alice), address(bob), 1);
        console.log(BasicERC721Contract.ownerOf(1));
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract BasicERC721 is ERC721, Ownable {
    constructor() ERC721("MyNFT", "MNFT") {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        // direct transfer
        _transfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}

contract ERC721B is ERC721, Ownable {
    constructor() ERC721("MyNFT", "MNFT") {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    /*
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
*/
}