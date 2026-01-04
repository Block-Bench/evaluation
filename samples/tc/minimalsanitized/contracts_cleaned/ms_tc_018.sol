// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract DODOPool {
    address public maintainer;
    address public baseToken;
    address public quoteToken;

    uint256 public lpFeeRate;
    uint256 public baseBalance;
    uint256 public quoteBalance;

    bool public isInitialized;

    event Initialized(address maintainer, address base, address quote);

    function init(
        address _maintainer,
        address _baseToken,
        address _quoteToken,
        uint256 _lpFeeRate
    ) external {
        

        maintainer = _maintainer;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        lpFeeRate = _lpFeeRate;

        
        isInitialized = true;

        emit Initialized(_maintainer, _baseToken, _quoteToken);
    }

    /**
     * @notice Add liquidity to pool
     */
    function addLiquidity(uint256 baseAmount, uint256 quoteAmount) external {
        require(isInitialized, "Not initialized");

        IERC20(baseToken).transferFrom(msg.sender, address(this), baseAmount);
        IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteAmount);

        baseBalance += baseAmount;
        quoteBalance += quoteAmount;
    }

    /**
     * @notice Swap tokens
     */
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external returns (uint256 toAmount) {
        require(isInitialized, "Not initialized");
        require(
            (fromToken == baseToken && toToken == quoteToken) ||
                (fromToken == quoteToken && toToken == baseToken),
            "Invalid token pair"
        );

        // Transfer tokens in
        IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);

        // Calculate swap amount (simplified constant product)
        if (fromToken == baseToken) {
            toAmount = (quoteBalance * fromAmount) / (baseBalance + fromAmount);
            baseBalance += fromAmount;
            quoteBalance -= toAmount;
        } else {
            toAmount = (baseBalance * fromAmount) / (quoteBalance + fromAmount);
            quoteBalance += fromAmount;
            baseBalance -= toAmount;
        }

        // Deduct fee for maintainer
        uint256 fee = (toAmount * lpFeeRate) / 10000;
        toAmount -= fee;

        // Transfer tokens out
        IERC20(toToken).transfer(msg.sender, toAmount);

        // they can claim all fees
        IERC20(toToken).transfer(maintainer, fee);

        return toAmount;
    }

    /**
     * @notice Claim accumulated fees (simplified)
     */
    function claimFees() external {
        require(msg.sender == maintainer, "Only maintainer");

        // In the real DODO contract, there was accumulated fee tracking
        // then claim all accumulated fees
        uint256 baseTokenBalance = IERC20(baseToken).balanceOf(address(this));
        uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));

        // Transfer excess (fees) to maintainer
        if (baseTokenBalance > baseBalance) {
            uint256 excess = baseTokenBalance - baseBalance;
            IERC20(baseToken).transfer(maintainer, excess);
        }

        if (quoteTokenBalance > quoteBalance) {
            uint256 excess = quoteTokenBalance - quoteBalance;
            IERC20(quoteToken).transfer(maintainer, excess);
        }
    }
}
