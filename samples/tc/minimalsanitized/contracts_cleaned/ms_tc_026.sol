// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract BeltStrategy {
    address public wantToken;
    address public oracle;
    uint256 public totalShares;
    
    mapping(address => uint256) public shares;
    
    constructor(address _want, address _oracle) {
        wantToken = _want;
        oracle = _oracle;
    }
    
    function deposit(uint256 amount) external returns (uint256 sharesAdded) {
        uint256 pool = IERC20(wantToken).balanceOf(address(this));
        
        if (totalShares == 0) {
            sharesAdded = amount;
        } else {
            uint256 price = IPriceOracle(oracle).getPrice(wantToken);
            sharesAdded = (amount * totalShares * 1e18) / (pool * price);
        }
        
        shares[msg.sender] += sharesAdded;
        totalShares += sharesAdded;
        
        IERC20(wantToken).transferFrom(msg.sender, address(this), amount);
        return sharesAdded;
    }
    
    function withdraw(uint256 sharesAmount) external {
        uint256 pool = IERC20(wantToken).balanceOf(address(this));
        
        uint256 price = IPriceOracle(oracle).getPrice(wantToken);
        uint256 amount = (sharesAmount * pool * price) / (totalShares * 1e18);
        
        shares[msg.sender] -= sharesAmount;
        totalShares -= sharesAmount;
        
        IERC20(wantToken).transfer(msg.sender, amount);
    }
}
