/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ 
/*LN-3*/ interface IERC20 {
/*LN-4*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-5*/ 
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ 
/*LN-16*/ contract GameLockManager {
/*LN-17*/     address public admin;
/*LN-18*/     address public configStorage;
/*LN-19*/ 
/*LN-20*/     struct PlayerSettings {
/*LN-21*/         uint256 lockedAmount;
/*LN-22*/         address lockRecipient;
/*LN-23*/         uint256 lockDuration;
/*LN-24*/         uint256 lockStartTime;
/*LN-25*/     }
/*LN-26*/ 
/*LN-27*/     mapping(address => PlayerSettings) public playerSettings;
/*LN-28*/     mapping(address => uint256) public playerBalances;
/*LN-29*/ 
/*LN-30*/     IERC20 public immutable weth;
/*LN-31*/ 
/*LN-32*/     event Locked(address player, uint256 amount, address recipient);
/*LN-33*/     event ConfigUpdated(address oldConfig, address newConfig);
/*LN-34*/ 
/*LN-35*/     constructor(address _weth) {
/*LN-36*/         admin = msg.sender;
/*LN-37*/         weth = IERC20(_weth);
/*LN-38*/     }
/*LN-39*/ 
/*LN-40*/ 
/*LN-41*/     modifier onlyAdmin() {
/*LN-42*/         require(msg.sender == admin, "Not admin");
/*LN-43*/         _;
/*LN-44*/     }
/*LN-45*/ 
/*LN-46*/ 
/*LN-47*/     function lock(uint256 amount, uint256 duration) external {
/*LN-48*/         require(amount > 0, "Zero amount");
/*LN-49*/ 
/*LN-50*/         weth.transferFrom(msg.sender, address(this), amount);
/*LN-51*/ 
/*LN-52*/         playerBalances[msg.sender] += amount;
/*LN-53*/         playerSettings[msg.sender] = PlayerSettings({
/*LN-54*/             lockedAmount: amount,
/*LN-55*/             lockRecipient: msg.sender,
/*LN-56*/             lockDuration: duration,
/*LN-57*/             lockStartTime: block.timestamp
/*LN-58*/         });
/*LN-59*/ 
/*LN-60*/         emit Locked(msg.sender, amount, msg.sender);
/*LN-61*/     }
/*LN-62*/ 
/*LN-63*/ 
/*LN-64*/     function setConfigStorage(address _configStorage) external onlyAdmin {
/*LN-65*/         address oldConfig = configStorage;
/*LN-66*/         configStorage = _configStorage;
/*LN-67*/ 
/*LN-68*/         emit ConfigUpdated(oldConfig, _configStorage);
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function setLockRecipient(
/*LN-72*/         address player,
/*LN-73*/         address newRecipient
/*LN-74*/     ) external onlyAdmin {
/*LN-75*/ 
/*LN-76*/         playerSettings[player].lockRecipient = newRecipient;
/*LN-77*/     }
/*LN-78*/ 
/*LN-79*/ 
/*LN-80*/     function unlock() external {
/*LN-81*/         PlayerSettings memory settings = playerSettings[msg.sender];
/*LN-82*/ 
/*LN-83*/         require(settings.lockedAmount > 0, "No locked tokens");
/*LN-84*/         require(
/*LN-85*/             block.timestamp >= settings.lockStartTime + settings.lockDuration,
/*LN-86*/             "Still locked"
/*LN-87*/         );
/*LN-88*/ 
/*LN-89*/         uint256 amount = settings.lockedAmount;
/*LN-90*/ 
/*LN-91*/         address recipient = settings.lockRecipient;
/*LN-92*/ 
/*LN-93*/         delete playerSettings[msg.sender];
/*LN-94*/         playerBalances[msg.sender] = 0;
/*LN-95*/ 
/*LN-96*/         weth.transfer(recipient, amount);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/ 
/*LN-100*/     function emergencyUnlock(address player) external onlyAdmin {
/*LN-101*/         PlayerSettings memory settings = playerSettings[player];
/*LN-102*/         uint256 amount = settings.lockedAmount;
/*LN-103*/         address recipient = settings.lockRecipient;
/*LN-104*/ 
/*LN-105*/         delete playerSettings[player];
/*LN-106*/         playerBalances[player] = 0;
/*LN-107*/ 
/*LN-108*/ 
/*LN-109*/         weth.transfer(recipient, amount);
/*LN-110*/     }
/*LN-111*/ 
/*LN-112*/ 
/*LN-113*/     function transferAdmin(address newAdmin) external onlyAdmin {
/*LN-114*/         admin = newAdmin;
/*LN-115*/     }
/*LN-116*/ }