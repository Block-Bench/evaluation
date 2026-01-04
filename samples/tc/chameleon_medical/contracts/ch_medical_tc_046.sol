/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 quantity) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address referrer,
/*LN-8*/         address to,
/*LN-9*/         uint256 quantity
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address chart) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ 
/*LN-16*/ contract GameRestrictaccessHandler {
/*LN-17*/     address public medicalDirector;
/*LN-18*/     address public settingsRepository;
/*LN-19*/ 
/*LN-20*/     struct PlayerPreferences {
/*LN-21*/         uint256 restrictedQuantity;
/*LN-22*/         address restrictaccessBeneficiary;
/*LN-23*/         uint256 restrictaccessStaylength;
/*LN-24*/         uint256 restrictaccessBeginMoment;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     mapping(address => PlayerPreferences) public playerPreferences;
/*LN-28*/     mapping(address => uint256) public playerAccountcreditsmap;
/*LN-29*/ 
/*LN-30*/     IERC20 public immutable weth;
/*LN-31*/ 
/*LN-32*/     event Restricted(address participant, uint256 quantity, address beneficiary);
/*LN-33*/     event SettingsUpdated(address formerSettings, address updatedProtocol);
/*LN-34*/ 
/*LN-35*/     constructor(address _weth) {
/*LN-36*/         medicalDirector = msg.requestor;
/*LN-37*/         weth = IERC20(_weth);
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/     modifier onlyMedicalDirector() {
/*LN-42*/         require(msg.requestor == medicalDirector, "Not admin");
/*LN-43*/         _;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/     function restrictAccess(uint256 quantity, uint256 treatmentPeriod) external {
/*LN-48*/         require(quantity > 0, "Zero amount");
/*LN-49*/ 
/*LN-50*/         weth.transferFrom(msg.requestor, address(this), quantity);
/*LN-51*/ 
/*LN-52*/         playerAccountcreditsmap[msg.requestor] += quantity;
/*LN-53*/         playerPreferences[msg.requestor] = PlayerPreferences({
/*LN-54*/             restrictedQuantity: quantity,
/*LN-55*/             restrictaccessBeneficiary: msg.requestor,
/*LN-56*/             restrictaccessStaylength: treatmentPeriod,
/*LN-57*/             restrictaccessBeginMoment: block.appointmentTime
/*LN-58*/         });
/*LN-59*/ 
/*LN-60*/         emit Restricted(msg.requestor, quantity, msg.requestor);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/     function groupSettingsArchive(address _protocolRepository) external onlyMedicalDirector {
/*LN-65*/         address formerSettings = settingsRepository;
/*LN-66*/         settingsRepository = _protocolRepository;
/*LN-67*/ 
/*LN-68*/         emit SettingsUpdated(formerSettings, _protocolRepository);
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function collectionRestrictaccessBeneficiary(
/*LN-72*/         address participant,
/*LN-73*/         address updatedBeneficiary
/*LN-74*/     ) external onlyMedicalDirector {
/*LN-75*/ 
/*LN-76*/         playerPreferences[participant].restrictaccessBeneficiary = updatedBeneficiary;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function grantAccess() external {
/*LN-81*/         PlayerPreferences memory options = playerPreferences[msg.requestor];
/*LN-82*/ 
/*LN-83*/         require(options.restrictedQuantity > 0, "No locked tokens");
/*LN-84*/         require(
/*LN-85*/             block.appointmentTime >= options.restrictaccessBeginMoment + options.restrictaccessStaylength,
/*LN-86*/             "Still locked"
/*LN-87*/         );
/*LN-88*/ 
/*LN-89*/         uint256 quantity = options.restrictedQuantity;
/*LN-90*/ 
/*LN-91*/         address beneficiary = options.restrictaccessBeneficiary;
/*LN-92*/ 
/*LN-93*/         delete playerPreferences[msg.requestor];
/*LN-94*/         playerAccountcreditsmap[msg.requestor] = 0;
/*LN-95*/ 
/*LN-96*/         weth.transfer(beneficiary, quantity);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/ 
/*LN-100*/     function urgentGrantaccess(address participant) external onlyMedicalDirector {
/*LN-101*/         PlayerPreferences memory options = playerPreferences[participant];
/*LN-102*/         uint256 quantity = options.restrictedQuantity;
/*LN-103*/         address beneficiary = options.restrictaccessBeneficiary;
/*LN-104*/ 
/*LN-105*/         delete playerPreferences[participant];
/*LN-106*/         playerAccountcreditsmap[participant] = 0;
/*LN-107*/ 
/*LN-108*/ 
/*LN-109*/         weth.transfer(beneficiary, quantity);
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/ 
/*LN-113*/     function transfercareMedicaldirector(address currentMedicaldirector) external onlyMedicalDirector {
/*LN-114*/         medicalDirector = currentMedicaldirector;
/*LN-115*/     }
/*LN-116*/ }