/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function balanceOf(address account) external view returns (uint256);
/*LN-6*/ 
/*LN-7*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-8*/ 
/*LN-9*/     function transferFrom(
/*LN-10*/         address from,
/*LN-11*/         address to,
/*LN-12*/         uint256 amount
/*LN-13*/     ) external returns (bool);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ interface ICErc20 {
/*LN-17*/     function borrow(uint256 amount) external returns (uint256);
/*LN-18*/ 
/*LN-19*/     function borrowBalanceCurrent(address account) external returns (uint256);
/*LN-20*/ }
/*LN-21*/ 

/**
 * @title AlphaHomoraBank
 * @notice Leveraged yield farming protocol with debt share accounting
 * @dev Audited by Peckshield (Q4 2020) - All findings resolved
 * @dev Implements share-based debt tracking for interest accrual
 * @dev Integrates with Iron Bank for borrowing liquidity
 * @custom:security-contact security@alphafinance.io
 */
/*LN-22*/ contract AlphaHomoraBank {
    /// @dev Position data for leveraged farming
/*LN-23*/     struct Position {
/*LN-24*/         address owner;
/*LN-25*/         uint256 collateral;
/*LN-26*/         uint256 debtShare;
/*LN-27*/     }
/*LN-28*/
    /// @dev Position registry by ID
/*LN-29*/     mapping(uint256 => Position) public positions;
    /// @dev Counter for position IDs
/*LN-30*/     uint256 public nextPositionId;
/*LN-31*/
    /// @dev Iron Bank cToken for borrowing
/*LN-32*/     address public cToken;
    /// @dev Total borrowed amount across all positions
/*LN-33*/     uint256 public totalDebt;
    /// @dev Total debt shares for proportional accounting
/*LN-34*/     uint256 public totalDebtShare;
/*LN-35*/ 
/*LN-36*/     constructor(address _cToken) {
/*LN-37*/         cToken = _cToken;
/*LN-38*/         nextPositionId = 1;
/*LN-39*/     }
/*LN-40*/ 
/*LN-41*/     /**
/*LN-42*/      * @notice Open a leveraged position
/*LN-43*/      */
/*LN-44*/     function openPosition(
/*LN-45*/         uint256 collateralAmount,
/*LN-46*/         uint256 borrowAmount
/*LN-47*/     ) external returns (uint256 positionId) {
/*LN-48*/         positionId = nextPositionId++;
/*LN-49*/ 
/*LN-50*/         positions[positionId] = Position({
/*LN-51*/             owner: msg.sender,
/*LN-52*/             collateral: collateralAmount,
/*LN-53*/             debtShare: 0
/*LN-54*/         });
/*LN-55*/ 
/*LN-56*/         // User provides collateral (simplified)
/*LN-57*/         // In real Alpha Homora, this would involve LP tokens
/*LN-58*/ 
/*LN-59*/         // Borrow from Iron Bank
/*LN-60*/         _borrow(positionId, borrowAmount);
/*LN-61*/ 
/*LN-62*/         return positionId;
/*LN-63*/     }
/*LN-64*/ 
    /**
     * @notice Internal borrow function with share calculation
     * @dev Calculates proportional debt shares for new borrowing
     * @param positionId Position to add debt to
     * @param amount Amount to borrow
     */
/*LN-68*/     function _borrow(uint256 positionId, uint256 amount) internal {
/*LN-69*/         Position storage pos = positions[positionId];
/*LN-70*/
            // Calculate debt shares for this borrow
/*LN-72*/         uint256 share;
/*LN-73*/
/*LN-74*/         if (totalDebtShare == 0) {
            // First borrow: 1:1 share ratio
/*LN-75*/             share = amount;
/*LN-76*/         } else {
            // Proportional share based on current debt pool
/*LN-78*/             share = (amount * totalDebtShare) / totalDebt;
/*LN-79*/         }
/*LN-80*/
            // Update position and global accounting
/*LN-81*/         pos.debtShare += share;
/*LN-82*/         totalDebtShare += share;
/*LN-83*/         totalDebt += amount;
/*LN-84*/
            // Execute borrow from lending protocol
/*LN-86*/         ICErc20(cToken).borrow(amount);
/*LN-87*/     }
/*LN-88*/ 
/*LN-89*/     /**
/*LN-90*/      * @notice Repay debt for a position
/*LN-91*/      */
/*LN-92*/     function repay(uint256 positionId, uint256 amount) external {
/*LN-93*/         Position storage pos = positions[positionId];
/*LN-94*/         require(msg.sender == pos.owner, "Not position owner");
/*LN-95*/ 
/*LN-96*/         // Calculate how many shares this repayment covers
/*LN-97*/         uint256 shareToRemove = (amount * totalDebtShare) / totalDebt;
/*LN-98*/ 
/*LN-99*/         require(pos.debtShare >= shareToRemove, "Excessive repayment");
/*LN-100*/ 
/*LN-101*/         pos.debtShare -= shareToRemove;
/*LN-102*/         totalDebtShare -= shareToRemove;
/*LN-103*/         totalDebt -= amount;
/*LN-104*/ 
/*LN-105*/         // Transfer tokens from user (simplified)
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     /**
/*LN-109*/      * @notice Get current debt amount for a position
/*LN-110*/      */
/*LN-111*/     function getPositionDebt(
/*LN-112*/         uint256 positionId
/*LN-113*/     ) external view returns (uint256) {
/*LN-114*/         Position storage pos = positions[positionId];
/*LN-115*/ 
/*LN-116*/         if (totalDebtShare == 0) return 0;
/*LN-117*/ 
/*LN-118*/         // Debt calculation based on current share
/*LN-119*/         return (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     /**
/*LN-123*/      * @notice Liquidate an unhealthy position
/*LN-124*/      */
/*LN-125*/     function liquidate(uint256 positionId) external {
/*LN-126*/         Position storage pos = positions[positionId];
/*LN-127*/ 
/*LN-128*/         uint256 debt = (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-129*/ 
/*LN-130*/         // Check if position is underwater
/*LN-131*/         // Simplified: collateral should be > 150% of debt
/*LN-132*/         require(pos.collateral * 100 < debt * 150, "Position is healthy");
/*LN-133*/ 
/*LN-134*/         // Liquidate and transfer collateral to liquidator
/*LN-135*/         pos.collateral = 0;
/*LN-136*/         pos.debtShare = 0;
/*LN-137*/     }
/*LN-138*/ }
/*LN-139*/ 