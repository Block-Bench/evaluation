// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/**
 */
contract SonneMarket {
    IERC20 public underlying;

    string public name = "Sonne WETH";
    string public symbol = "soWETH";
    uint8 public decimals = 8;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // Compound-style interest rate tracking
    uint256 public totalBorrows;
    uint256 public totalReserves;

    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    constructor(address _underlying) {
        underlying = IERC20(_underlying);
    }

    function exchangeRate() public view returns (uint256) {
        if (totalSupply == 0) {
            return 1e18; // Initial exchange rate: 1:1
        }

        uint256 cash = underlying.balanceOf(address(this));

        // exchangeRate = (cash + totalBorrows - totalReserves) / totalSupply
        uint256 totalUnderlying = cash + totalBorrows - totalReserves;

        return (totalUnderlying * 1e18) / totalSupply;
    }

    /**
     * @dev Supply underlying tokens, receive cTokens
     */
    function mint(uint256 mintAmount) external returns (uint256) {
        require(mintAmount > 0, "Zero mint");

        uint256 exchangeRateMantissa = exchangeRate();

        // Calculate cTokens to mint: mintAmount * 1e18 / exchangeRate
        uint256 mintTokens = (mintAmount * 1e18) / exchangeRateMantissa;

        

        totalSupply += mintTokens;
        balanceOf[msg.sender] += mintTokens;

        underlying.transferFrom(msg.sender, address(this), mintAmount);

        emit Mint(msg.sender, mintAmount, mintTokens);
        return mintTokens;
    }

    /**
     * @dev Redeem cTokens for underlying based on current exchange rate
     */
    function redeem(uint256 redeemTokens) external returns (uint256) {
        require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");

        uint256 exchangeRateMantissa = exchangeRate();

        // Calculate underlying: redeemTokens * exchangeRate / 1e18
        uint256 redeemAmount = (redeemTokens * exchangeRateMantissa) / 1e18;

        balanceOf[msg.sender] -= redeemTokens;
        totalSupply -= redeemTokens;

        underlying.transfer(msg.sender, redeemAmount);

        emit Redeem(msg.sender, redeemAmount, redeemTokens);
        return redeemAmount;
    }

    /**
     * @dev Get account's current underlying balance (for collateral calculation)
     */
    function balanceOfUnderlying(
        address account
    ) external view returns (uint256) {
        uint256 exchangeRateMantissa = exchangeRate();

        
        return (balanceOf[account] * exchangeRateMantissa) / 1e18;
    }
}
