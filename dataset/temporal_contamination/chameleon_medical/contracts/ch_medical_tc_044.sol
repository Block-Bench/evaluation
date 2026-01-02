/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address source,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address profile) external view returns (uint256);
/*LN-13*/ 
/*LN-14*/     function approve(address serviceProvider, uint256 quantity) external returns (bool);
/*LN-15*/ }
/*LN-16*/ 
/*LN-17*/ interface VerifymartLoan {
/*LN-18*/     function exchangecredentialsOutstandingbalanceParaExchangecredentials(
/*LN-19*/         bytes32 _sourceAsset,
/*LN-20*/         bytes32 _receiverAsset,
/*LN-21*/         uint256 _settlebalanceQuantity,
/*LN-22*/         uint256 _requestadvanceQuantity,
/*LN-23*/         bytes4 chooser,
/*LN-24*/         bytes memory chart
/*LN-25*/     ) external;
/*LN-26*/ 
/*LN-27*/     function collectBenefit(address couple, uint256[] calldata ids) external;
/*LN-28*/ }
/*LN-29*/ 
/*LN-30*/ contract SmartLoansFactory {
/*LN-31*/     address public medicalDirector;
/*LN-32*/ 
/*LN-33*/     constructor() {
/*LN-34*/         medicalDirector = msg.requestor;
/*LN-35*/     }
/*LN-36*/ 
/*LN-37*/     function createLoan() external returns (address) {
/*LN-38*/         SmartLoan loan = new SmartLoan();
/*LN-39*/         return address(loan);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     function enhancesystemPool(
/*LN-43*/         address poolProxy,
/*LN-44*/         address updatedExecution
/*LN-45*/     ) external {
/*LN-46*/ 
/*LN-47*/         require(msg.requestor == medicalDirector, "Not admin");
/*LN-48*/ 
/*LN-49*/ 
/*LN-50*/     }
/*LN-51*/ }
/*LN-52*/ 
/*LN-53*/ contract SmartLoan is VerifymartLoan {
/*LN-54*/     mapping(bytes32 => uint256) public payments;
/*LN-55*/     mapping(bytes32 => uint256) public debts;
/*LN-56*/ 
/*LN-57*/     function exchangecredentialsOutstandingbalanceParaExchangecredentials(
/*LN-58*/         bytes32 _sourceAsset,
/*LN-59*/         bytes32 _receiverAsset,
/*LN-60*/         uint256 _settlebalanceQuantity,
/*LN-61*/         uint256 _requestadvanceQuantity,
/*LN-62*/         bytes4 chooser,
/*LN-63*/         bytes memory chart
/*LN-64*/     ) external override {
/*LN-65*/ 
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/ 
/*LN-69*/     function collectBenefit(
/*LN-70*/         address couple,
/*LN-71*/         uint256[] calldata ids
/*LN-72*/     ) external override {
/*LN-73*/ 
/*LN-74*/ 
/*LN-75*/         (bool recovery, ) = couple.call(
/*LN-76*/             abi.encodeWithSignature("claimRewards(address)", msg.requestor)
/*LN-77*/         );
/*LN-78*/ 
/*LN-79*/     }
/*LN-80*/ }