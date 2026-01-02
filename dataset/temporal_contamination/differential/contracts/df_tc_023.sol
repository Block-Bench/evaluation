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
/*LN-22*/ contract LeveragedVault {
/*LN-23*/     struct Position {
/*LN-24*/         address owner;
/*LN-25*/         uint256 collateral;
/*LN-26*/         uint256 debtShare;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(uint256 => Position) public positions;
/*LN-30*/     uint256 public nextPositionId;
/*LN-31*/ 
/*LN-32*/     address public cToken;
/*LN-33*/     uint256 public totalDebt;
/*LN-34*/     uint256 public totalDebtShare;
/*LN-35*/ 
/*LN-36*/     uint256 public constant MINIMUM_SHARE = 1000;
/*LN-37*/ 
/*LN-38*/     constructor(address _cToken) {
/*LN-39*/         cToken = _cToken;
/*LN-40*/         nextPositionId = 1;
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     function openPosition(
/*LN-44*/         uint256 collateralAmount,
/*LN-45*/         uint256 borrowAmount
/*LN-46*/     ) external returns (uint256 positionId) {
/*LN-47*/         positionId = nextPositionId++;
/*LN-48*/ 
/*LN-49*/         positions[positionId] = Position({
/*LN-50*/             owner: msg.sender,
/*LN-51*/             collateral: collateralAmount,
/*LN-52*/             debtShare: 0
/*LN-53*/         });
/*LN-54*/ 
/*LN-55*/         _borrow(positionId, borrowAmount);
/*LN-56*/ 
/*LN-57*/         return positionId;
/*LN-58*/     }
/*LN-59*/ 
/*LN-60*/     function _borrow(uint256 positionId, uint256 amount) internal {
/*LN-61*/         Position storage pos = positions[positionId];
/*LN-62*/ 
/*LN-63*/         uint256 share;
/*LN-64*/ 
/*LN-65*/         if (totalDebtShare == 0) {
/*LN-66*/             share = amount;
/*LN-67*/             require(share >= MINIMUM_SHARE, "Initial share too small");
/*LN-68*/         } else {
/*LN-69*/             share = (amount * totalDebtShare) / totalDebt;
/*LN-70*/             require(share >= MINIMUM_SHARE, "Share too small");
/*LN-71*/         }
/*LN-72*/ 
/*LN-73*/         pos.debtShare += share;
/*LN-74*/         totalDebtShare += share;
/*LN-75*/         totalDebt += amount;
/*LN-76*/ 
/*LN-77*/         ICErc20(cToken).borrow(amount);
/*LN-78*/     }
/*LN-79*/ 
/*LN-80*/     function repay(uint256 positionId, uint256 amount) external {
/*LN-81*/         Position storage pos = positions[positionId];
/*LN-82*/         require(msg.sender == pos.owner, "Not position owner");
/*LN-83*/ 
/*LN-84*/         uint256 shareToRemove = (amount * totalDebtShare) / totalDebt;
/*LN-85*/ 
/*LN-86*/         require(pos.debtShare >= shareToRemove, "Excessive repayment");
/*LN-87*/ 
/*LN-88*/         pos.debtShare -= shareToRemove;
/*LN-89*/         totalDebtShare -= shareToRemove;
/*LN-90*/         totalDebt -= amount;
/*LN-91*/     }
/*LN-92*/ 
/*LN-93*/     function getPositionDebt(
/*LN-94*/         uint256 positionId
/*LN-95*/     ) external view returns (uint256) {
/*LN-96*/         Position storage pos = positions[positionId];
/*LN-97*/ 
/*LN-98*/         if (totalDebtShare == 0) return 0;
/*LN-99*/ 
/*LN-100*/         return (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function liquidate(uint256 positionId) external {
/*LN-104*/         Position storage pos = positions[positionId];
/*LN-105*/ 
/*LN-106*/         uint256 debt = (pos.debtShare * totalDebt) / totalDebtShare;
/*LN-107*/ 
/*LN-108*/         require(pos.collateral * 100 < debt * 150, "Position is healthy");
/*LN-109*/ 
/*LN-110*/         pos.collateral = 0;
/*LN-111*/         pos.debtShare = 0;
/*LN-112*/     }
/*LN-113*/ }
/*LN-114*/ 