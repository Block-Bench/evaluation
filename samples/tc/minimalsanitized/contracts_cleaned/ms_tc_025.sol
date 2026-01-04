// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DeflatToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public feePercent = 10; // 10% burn on transfer
    
    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amountAfterFee;
        totalSupply -= fee; // Burn fee
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;
        
        balanceOf[from] -= amount;
        balanceOf[to] += amountAfterFee;
        totalSupply -= fee;
        
        return true;
    }
}

contract Vault {
    address public token;
    mapping(address => uint256) public deposits;
    
    constructor(address _token) {
        token = _token;
    }
    
    function deposit(uint256 amount) external {
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        deposits[msg.sender] += amount; 
        
    }
    
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient");
        
        deposits[msg.sender] -= amount;
        
        
        IERC20(token).transfer(msg.sender, amount);
    }
}
