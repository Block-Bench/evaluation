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

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract WiseLending {
    struct PoolData {
        uint256 pseudoTotalPool;
        uint256 totalDepositShares;
        uint256 totalBorrowShares;
        uint256 collateralFactor;
    }

    mapping(address => PoolData) public lendingPoolData;
    mapping(uint256 => mapping(address => uint256)) public userLendingShares;
    mapping(uint256 => mapping(address => uint256)) public userBorrowShares;

    IERC721 public positionNFTs;
    uint256 public nftIdCounter;

    /**
     * @notice Mint position NFT
     */
    function mintPosition() external returns (uint256) {
        uint256 nftId = ++nftIdCounter;
        return nftId;
    }

    /**
     * @notice Deposit exact amount of tokens
     */
    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    ) external returns (uint256 shareAmount) {
        IERC20(_poolToken).transferFrom(msg.sender, address(this), _amount);

        PoolData storage pool = lendingPoolData[_poolToken];

        // (e.g., 2 wei and 1 wei), rounding errors become significant

        if (pool.totalDepositShares == 0) {
            shareAmount = _amount;
            pool.totalDepositShares = _amount;
        } else {
            
            
            
            shareAmount =
                (_amount * pool.totalDepositShares) /
                pool.pseudoTotalPool;
            pool.totalDepositShares += shareAmount;
        }

        pool.pseudoTotalPool += _amount;
        userLendingShares[_nftId][_poolToken] += shareAmount;

        return shareAmount;
    }

    /**
     * @notice Withdraw exact shares amount
     */
    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    ) external returns (uint256 withdrawAmount) {
        require(
            userLendingShares[_nftId][_poolToken] >= _shares,
            "Insufficient shares"
        );

        PoolData storage pool = lendingPoolData[_poolToken];

        // withdrawAmount = (_shares * pseudoTotalPool) / totalDepositShares
        
        
       

        withdrawAmount =
            (_shares * pool.pseudoTotalPool) /
            pool.totalDepositShares;

        userLendingShares[_nftId][_poolToken] -= _shares;
        pool.totalDepositShares -= _shares;
        pool.pseudoTotalPool -= withdrawAmount;

        IERC20(_poolToken).transfer(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Withdraw exact amount of tokens
     */
    function withdrawExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _withdrawAmount
    ) external returns (uint256 shareBurned) {
        PoolData storage pool = lendingPoolData[_poolToken];

        shareBurned =
            (_withdrawAmount * pool.totalDepositShares) /
            pool.pseudoTotalPool;

        require(
            userLendingShares[_nftId][_poolToken] >= shareBurned,
            "Insufficient shares"
        );

        userLendingShares[_nftId][_poolToken] -= shareBurned;
        pool.totalDepositShares -= shareBurned;
        pool.pseudoTotalPool -= _withdrawAmount;

        IERC20(_poolToken).transfer(msg.sender, _withdrawAmount);

        return shareBurned;
    }

    /**
     * @notice Get position lending shares
     */
    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    ) external view returns (uint256) {
        return userLendingShares[_nftId][_poolToken];
    }

    /**
     * @notice Get total pool balance
     */
    function getTotalPool(address _poolToken) external view returns (uint256) {
        return lendingPoolData[_poolToken].pseudoTotalPool;
    }
}
