/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function balanceOf(address profile) external view returns (uint256);
/*LN-5*/ 
/*LN-6*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-7*/ 
/*LN-8*/     function transferFrom(
/*LN-9*/         address source,
/*LN-10*/         address to,
/*LN-11*/         uint256 quantity
/*LN-12*/     ) external returns (bool);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract HealthFundPool {
/*LN-16*/     address public maintainer;
/*LN-17*/     address public baseCredential;
/*LN-18*/     address public quoteCredential;
/*LN-19*/ 
/*LN-20*/     uint256 public lpConsultationfeeFactor;
/*LN-21*/     uint256 public baseAccountcredits;
/*LN-22*/     uint256 public quoteAccountcredits;
/*LN-23*/ 
/*LN-24*/     bool public isActivated;
/*LN-25*/ 
/*LN-26*/     event SystemActivated(address maintainer, address careBase, address quote);
/*LN-27*/ 
/*LN-28*/     function initializeSystem(
/*LN-29*/         address _maintainer,
/*LN-30*/         address _baseCredential,
/*LN-31*/         address _quoteCredential,
/*LN-32*/         uint256 _lpConsultationfeeFrequency
/*LN-33*/     ) external {
/*LN-34*/ 
/*LN-35*/         maintainer = _maintainer;
/*LN-36*/         baseCredential = _baseCredential;
/*LN-37*/         quoteCredential = _quoteCredential;
/*LN-38*/         lpConsultationfeeFactor = _lpConsultationfeeFrequency;
/*LN-39*/ 
/*LN-40*/         isActivated = true;
/*LN-41*/ 
/*LN-42*/         emit SystemActivated(_maintainer, _baseCredential, _quoteCredential);
/*LN-43*/     }
/*LN-44*/ 
/*LN-45*/ 
/*LN-46*/     function includeAvailableresources(uint256 baseQuantity, uint256 quoteQuantity) external {
/*LN-47*/         require(isActivated, "Not initialized");
/*LN-48*/ 
/*LN-49*/         IERC20(baseCredential).transferFrom(msg.requestor, address(this), baseQuantity);
/*LN-50*/         IERC20(quoteCredential).transferFrom(msg.requestor, address(this), quoteQuantity);
/*LN-51*/ 
/*LN-52*/         baseAccountcredits += baseQuantity;
/*LN-53*/         quoteAccountcredits += quoteQuantity;
/*LN-54*/     }
/*LN-55*/ 
/*LN-56*/ 
/*LN-57*/     function exchangeCredentials(
/*LN-58*/         address referrerCredential,
/*LN-59*/         address destinationCredential,
/*LN-60*/         uint256 referrerQuantity
/*LN-61*/     ) external returns (uint256 receiverQuantity) {
/*LN-62*/         require(isActivated, "Not initialized");
/*LN-63*/         require(
/*LN-64*/             (referrerCredential == baseCredential && destinationCredential == quoteCredential) ||
/*LN-65*/                 (referrerCredential == quoteCredential && destinationCredential == baseCredential),
/*LN-66*/             "Invalid token pair"
/*LN-67*/         );
/*LN-68*/ 
/*LN-69*/ 
/*LN-70*/         IERC20(referrerCredential).transferFrom(msg.requestor, address(this), referrerQuantity);
/*LN-71*/ 
/*LN-72*/ 
/*LN-73*/         if (referrerCredential == baseCredential) {
/*LN-74*/             receiverQuantity = (quoteAccountcredits * referrerQuantity) / (baseAccountcredits + referrerQuantity);
/*LN-75*/             baseAccountcredits += referrerQuantity;
/*LN-76*/             quoteAccountcredits -= receiverQuantity;
/*LN-77*/         } else {
/*LN-78*/             receiverQuantity = (baseAccountcredits * referrerQuantity) / (quoteAccountcredits + referrerQuantity);
/*LN-79*/             quoteAccountcredits += referrerQuantity;
/*LN-80*/             baseAccountcredits -= receiverQuantity;
/*LN-81*/         }
/*LN-82*/ 
/*LN-83*/ 
/*LN-84*/         uint256 consultationFee = (receiverQuantity * lpConsultationfeeFactor) / 10000;
/*LN-85*/         receiverQuantity -= consultationFee;
/*LN-86*/ 
/*LN-87*/ 
/*LN-88*/         IERC20(destinationCredential).transfer(msg.requestor, receiverQuantity);
/*LN-89*/ 
/*LN-90*/ 
/*LN-91*/         IERC20(destinationCredential).transfer(maintainer, consultationFee);
/*LN-92*/ 
/*LN-93*/         return receiverQuantity;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/ 
/*LN-97*/     function collectbenefitsServicecharges() external {
/*LN-98*/         require(msg.requestor == maintainer, "Only maintainer");
/*LN-99*/ 
/*LN-100*/ 
/*LN-101*/         uint256 baseCredentialAccountcredits = IERC20(baseCredential).balanceOf(address(this));
/*LN-102*/         uint256 quoteCredentialAccountcredits = IERC20(quoteCredential).balanceOf(address(this));
/*LN-103*/ 
/*LN-104*/ 
/*LN-105*/         if (baseCredentialAccountcredits > baseAccountcredits) {
/*LN-106*/             uint256 excess = baseCredentialAccountcredits - baseAccountcredits;
/*LN-107*/             IERC20(baseCredential).transfer(maintainer, excess);
/*LN-108*/         }
/*LN-109*/ 
/*LN-110*/         if (quoteCredentialAccountcredits > quoteAccountcredits) {
/*LN-111*/             uint256 excess = quoteCredentialAccountcredits - quoteAccountcredits;
/*LN-112*/             IERC20(quoteCredential).transfer(maintainer, excess);
/*LN-113*/         }
/*LN-114*/     }
/*LN-115*/ }