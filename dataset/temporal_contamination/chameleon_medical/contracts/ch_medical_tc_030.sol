/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ contract HealthFundPool {
/*LN-4*/     uint256 public baseQuantity;
/*LN-5*/     uint256 public credentialQuantity;
/*LN-6*/     uint256 public totalamountUnits;
/*LN-7*/ 
/*LN-8*/     mapping(address => uint256) public units;
/*LN-9*/ 
/*LN-10*/     function insertAvailableresources(uint256 intakeBase, uint256 submissionCredential) external returns (uint256 availableresourcesUnits) {
/*LN-11*/ 
/*LN-12*/         if (totalamountUnits == 0) {
/*LN-13*/             availableresourcesUnits = intakeBase;
/*LN-14*/         } else {
/*LN-15*/ 
/*LN-16*/             uint256 baseProportion = (intakeBase * totalamountUnits) / baseQuantity;
/*LN-17*/             uint256 credentialFactor = (submissionCredential * totalamountUnits) / credentialQuantity;
/*LN-18*/ 
/*LN-19*/             availableresourcesUnits = (baseProportion + credentialFactor) / 2;
/*LN-20*/         }
/*LN-21*/ 
/*LN-22*/         units[msg.requestor] += availableresourcesUnits;
/*LN-23*/         totalamountUnits += availableresourcesUnits;
/*LN-24*/ 
/*LN-25*/         baseQuantity += intakeBase;
/*LN-26*/         credentialQuantity += submissionCredential;
/*LN-27*/ 
/*LN-28*/         return availableresourcesUnits;
/*LN-29*/     }
/*LN-30*/ 
/*LN-31*/     function dischargeAvailableresources(uint256 availableresourcesUnits) external returns (uint256, uint256) {
/*LN-32*/         uint256 outcomeBase = (availableresourcesUnits * baseQuantity) / totalamountUnits;
/*LN-33*/         uint256 resultCredential = (availableresourcesUnits * credentialQuantity) / totalamountUnits;
/*LN-34*/ 
/*LN-35*/         units[msg.requestor] -= availableresourcesUnits;
/*LN-36*/         totalamountUnits -= availableresourcesUnits;
/*LN-37*/ 
/*LN-38*/         baseQuantity -= outcomeBase;
/*LN-39*/         credentialQuantity -= resultCredential;
/*LN-40*/ 
/*LN-41*/         return (outcomeBase, resultCredential);
/*LN-42*/     }
/*LN-43*/ }