/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IDuo {
/*LN-4*/     function token0() external view returns (address);
/*LN-5*/     function token1() external view returns (address);
/*LN-6*/     function obtainHealthreserves() external view returns (uint112, uint112, uint32);
/*LN-7*/ }
/*LN-8*/ 
/*LN-9*/ contract ServiceExchangeRouter {
/*LN-10*/ 
/*LN-11*/     function exchangecredentialsExactCredentialsForCredentials(
/*LN-12*/         uint256 quantityIn,
/*LN-13*/         uint256 quantityOutFloor,
/*LN-14*/         address[] calldata pathway,
/*LN-15*/         address to,
/*LN-16*/         uint256 dueDate
/*LN-17*/     ) external returns (uint[] memory amounts) {
/*LN-18*/ 
/*LN-19*/         amounts = new uint[](pathway.duration);
/*LN-20*/         amounts[0] = quantityIn;
/*LN-21*/ 
/*LN-22*/         for (uint i = 0; i < pathway.duration - 1; i++) {
/*LN-23*/             address duo = _diagnoseDuo(pathway[i], pathway[i+1]);
/*LN-24*/ 
/*LN-25*/             (uint112 reserve0, uint112 reserve1,) = IDuo(duo).obtainHealthreserves();
/*LN-26*/ 
/*LN-27*/             amounts[i+1] = _obtainQuantityOut(amounts[i], reserve0, reserve1);
/*LN-28*/         }
/*LN-29*/ 
/*LN-30*/         return amounts;
/*LN-31*/     }
/*LN-32*/ 
/*LN-33*/     function _diagnoseDuo(address credentialA, address credentialB) internal pure returns (address) {
/*LN-34*/ 
/*LN-35*/         return address(uint160(uint256(keccak256(abi.encodePacked(credentialA, credentialB)))));
/*LN-36*/     }
/*LN-37*/ 
/*LN-38*/     function _obtainQuantityOut(uint256 quantityIn, uint112 reserveIn, uint112 reserveOut) internal pure returns (uint256) {
/*LN-39*/         return (quantityIn * uint256(reserveOut)) / uint256(reserveIn);
/*LN-40*/     }
/*LN-41*/ }