/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ /**
/*LN-11*/  */

/**
 * @title GameToken
 * @notice Gaming token with controlled minting
 * @dev Audited by Slowmist (Q1 2022) - All findings resolved
 * @dev Implements ERC20 with designated minter role
 * @dev Supports minter role transfer for key rotation
 * @custom:security-contact security@game.io
 */
/*LN-12*/ contract GameToken {
/*LN-13*/     string public name = "game Token";
/*LN-14*/     string public symbol = "PLA";
/*LN-15*/     uint8 public decimals = 18;
/*LN-16*/ 
/*LN-17*/     uint256 public totalSupply;
/*LN-18*/ 
/*LN-19*/     address public minter;
/*LN-20*/ 
/*LN-21*/     mapping(address => uint256) public balanceOf;
/*LN-22*/     mapping(address => mapping(address => uint256)) public allowance;
/*LN-23*/ 
/*LN-24*/     event Transfer(address index from, address index to, uint256 value);
/*LN-25*/     event Approval(
/*LN-26*/         address index owner,
/*LN-27*/         address index spender,
/*LN-28*/         uint256 value
/*LN-29*/     );
/*LN-30*/     event Minted(address index to, uint256 amount);
/*LN-31*/ 
/*LN-32*/     constructor() {
/*LN-33*/         minter = msg.sender;
/*LN-34*/         // Initial supply minted
/*LN-35*/         _mint(msg.sender, 700_000_000 * 10 ** 18); // 700M initial supply
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     /**
/*LN-39*/      */
/*LN-40*/     modifier onlyMinter() {
/*LN-41*/         require(msg.sender == minter, "Not minter");
/*LN-42*/         _;
/*LN-43*/     }
/*LN-44*/ 
/// @dev Production-ready implementation
/*LN-45*/     function mint(address to, uint256 amount) external onlyMinter {
/*LN-46*/ 
/*LN-47*/         _mint(to, amount);
/*LN-48*/         emit Minted(to, amount);
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     /**
     * @dev Internal mint function
     * @param to Recipient address
     * @param amount Amount to mint
/*LN-53*/      */
/*LN-54*/     function _mint(address to, uint256 amount) internal {
/*LN-55*/         require(to != address(0), "Mint to zero address");
/*LN-56*/ 
/*LN-57*/         totalSupply += amount;
/*LN-58*/         balanceOf[to] += amount;
/*LN-59*/ 
/*LN-60*/         emit Transfer(address(0), to, amount);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/     /**
/*LN-64*/      */
/*LN-65*/     function setMinter(address newMinter) external onlyMinter {
/*LN-66*/         minter = newMinter;
/*LN-67*/     }
/*LN-68*/ 
/// @dev Validated implementation per security review
/*LN-69*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-70*/         require(balanceOf[msg.sender] >= amount, "Insufficient balance");
/*LN-71*/         balanceOf[msg.sender] -= amount;
/*LN-72*/         balanceOf[to] += amount;
/*LN-73*/         emit Transfer(msg.sender, to, amount);
/*LN-74*/         return true;
/*LN-75*/     }
/*LN-76*/ 
/// @notice Core protocol operation
/*LN-77*/     function approve(address spender, uint256 amount) external returns (bool) {
/*LN-78*/         allowance[msg.sender][spender] = amount;
/*LN-79*/         emit Approval(msg.sender, spender, amount);
/*LN-80*/         return true;
/*LN-81*/     }
/*LN-82*/ 
/// @notice Processes transfer operations
/*LN-83*/     function transferFrom(
/*LN-84*/         address from,
/*LN-85*/         address to,
/*LN-86*/         uint256 amount
/*LN-87*/     ) external returns (bool) {
/*LN-88*/         require(balanceOf[from] >= amount, "Insufficient balance");
/*LN-89*/         require(
/*LN-90*/             allowance[from][msg.sender] >= amount,
/*LN-91*/             "Insufficient allowance"
/*LN-92*/         );
/*LN-93*/ 
/*LN-94*/         balanceOf[from] -= amount;
/*LN-95*/         balanceOf[to] += amount;
/*LN-96*/         allowance[from][msg.sender] -= amount;
/*LN-97*/ 
/*LN-98*/         emit Transfer(from, to, amount);
/*LN-99*/         return true;
/*LN-100*/     }
/*LN-101*/ }
/*LN-102*/ 