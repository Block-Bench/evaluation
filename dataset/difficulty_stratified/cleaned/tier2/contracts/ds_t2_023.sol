// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractTest is Test {
    BasicBank BasicBankContract;
    BanksLP BanksLPContract;
    BasicBankB BankContractB;
    address alice = vm.addr(1);

    function setUp() public {
        BasicBankContract = new BasicBank();
        BankContractB = new BasicBankB();
        BanksLPContract = new BanksLP();
        BanksLPContract.transfer(address(alice), 10000);
        BanksLPContract.transfer(address(BasicBankContract), 100000);
    }

    function testBasicBankA() public {
        console.log("Current timestamp", block.timestamp);
        vm.startPrank(alice);
        BanksLPContract.approve(address(BasicBankContract), 10000);
        console.log(
            "Before locking, my BanksLP balance",
            BanksLPContract.balanceOf(address(alice))
        );
        BasicBankContract.createLocker(
            address(BanksLPContract),
            10000,
            86400
        );
        console.log(
            "Before operation",
            BanksLPContract.balanceOf(address(alice))
        );

        for (uint i = 0; i < 10; i++) {
            BasicBankContract.unlockToken(1);
        }
        console.log(
            "After operation",
            BanksLPContract.balanceOf(address(alice))
        );
    }

    function testBasicBankB() public {
        console.log("Current timestamp", block.timestamp);
        vm.startPrank(alice);
        BanksLPContract.approve(address(BankContractB), 10000);
        console.log(
            "Before locking, my BanksLP balance",
            BanksLPContract.balanceOf(address(alice))
        );
        BankContractB.createLocker(address(BanksLPContract), 10000, 86400);
        console.log(
            "Before operation",
            BanksLPContract.balanceOf(address(alice))
        );

        for (uint i = 0; i < 10; i++) {
            {
                vm.expectRevert();
                BankContractB.unlockToken(1);
            }
        }
        console.log(
            "After operation",
            BanksLPContract.balanceOf(address(alice))
        );
    }
}

contract BasicBank {
    struct Locker {
        bool hasLockedTokens;
        uint256 amount;
        uint256 lockTime;
        address tokenAddress;
    }

    mapping(address => mapping(uint256 => Locker)) private _unlockToken;
    uint256 private _nextLockerId = 1;

    function createLocker(
        address tokenAddress,
        uint256 amount,
        uint256 lockTime
    ) public {
        require(amount > 0, "Amount must be greater than 0");
        require(lockTime > block.timestamp, "Lock time must be in the future");
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        Locker storage locker = _unlockToken[msg.sender][_nextLockerId];
        locker.hasLockedTokens = true;
        locker.amount = amount;
        locker.lockTime = lockTime;
        locker.tokenAddress = tokenAddress;

        _nextLockerId++;
    }

    function unlockToken(uint256 lockerId) public {
        Locker storage locker = _unlockToken[msg.sender][lockerId];
        uint256 amount = locker.amount;
        require(locker.hasLockedTokens, "No locked tokens");

        if (block.timestamp > locker.lockTime) {
            locker.amount = 0;
        }

        IERC20(locker.tokenAddress).transfer(msg.sender, amount);
    }
}

contract BanksLP is ERC20, Ownable {
    constructor() ERC20("BanksLP", "BanksLP") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract BasicBankB {
    struct Locker {
        bool hasLockedTokens;
        uint256 amount;
        uint256 lockTime;
        address tokenAddress;
    }

    mapping(address => mapping(uint256 => Locker)) private _unlockToken;
    uint256 private _nextLockerId = 1;

    function createLocker(
        address tokenAddress,
        uint256 amount,
        uint256 lockTime
    ) public {
        require(amount > 0, "Amount must be greater than 0");
        require(lockTime > block.timestamp, "Lock time must be in the future");
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        Locker storage locker = _unlockToken[msg.sender][_nextLockerId];
        locker.hasLockedTokens = true;
        locker.amount = amount;
        locker.lockTime = lockTime;
        locker.tokenAddress = tokenAddress;

        _nextLockerId++;
    }

    function unlockToken(uint256 lockerId) public {
        Locker storage locker = _unlockToken[msg.sender][lockerId];

        require(locker.hasLockedTokens, "No locked tokens");
        require(block.timestamp > locker.lockTime, "Tokens are still locked");
        uint256 amount = locker.amount;

        locker.hasLockedTokens = false;
        locker.amount = 0;

        IERC20(locker.tokenAddress).transfer(msg.sender, amount);
    }
}
