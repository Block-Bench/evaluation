// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/**
 */
contract PlayDappToken {
    string public name = "PlayDapp Token";
    string public symbol = "PLA";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    address public minter;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Minted(address indexed to, uint256 amount);

    constructor() {
        minter = msg.sender;
        // Initial supply minted
        _mint(msg.sender, 700_000_000 * 10 ** 18); // 700M initial supply
    }

    /**
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, uint256 amount) external onlyMinter {

        _mint(to, amount);
        emit Minted(to, amount);
    }

    /**
     * @dev Internal mint function with no safeguards
     */
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    /**
     */
    function setMinter(address newMinter) external onlyMinter {
        minter = newMinter;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(
            allowance[from][msg.sender] >= amount,
            "Insufficient allowance"
        );

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
