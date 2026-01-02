/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/ 
/*LN-7*/     function transferFrom(
/*LN-8*/         address from,
/*LN-9*/         address to,
/*LN-10*/         uint256 amount
/*LN-11*/     ) external returns (bool);
/*LN-12*/ 
/*LN-13*/     function balanceOf(address account) external view returns (uint256);
/*LN-14*/ }
/*LN-15*/ 
/*LN-16*/ /**
/*LN-17*/  */
/*LN-18*/ contract GameLockManager {
/*LN-19*/     address public admin;
/*LN-20*/     address public configStorage;
/*LN-21*/ 
/*LN-22*/     struct PlayerSettings {
/*LN-23*/         uint256 lockedAmount;
/*LN-24*/         address lockRecipient;
/*LN-25*/         uint256 lockDuration;
/*LN-26*/         uint256 lockStartTime;
/*LN-27*/     }
/*LN-28*/ 
/*LN-29*/     mapping(address => PlayerSettings) public playerSettings;
/*LN-30*/     mapping(address => uint256) public playerBalances;
/*LN-31*/ 
/*LN-32*/     IERC20 public immutable weth;
/*LN-33*/ 
/*LN-34*/     event Locked(address player, uint256 amount, address recipient);
/*LN-35*/     event ConfigUpdated(address oldConfig, address newConfig);
/*LN-36*/ 
/*LN-37*/     constructor(address _weth) {
/*LN-38*/         admin = msg.sender;
/*LN-39*/         weth = IERC20(_weth);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     /**
/*LN-43*/      */
/*LN-44*/     modifier onlyAdmin() {
/*LN-45*/         require(msg.sender == admin, "Not admin");
/*LN-46*/         _;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     /**
/*LN-50*/      * @dev Users lock tokens to earn rewards
/*LN-51*/      */
/*LN-52*/     function lock(uint256 amount, uint256 duration) external {
/*LN-53*/         require(amount > 0, "Zero amount");
/*LN-54*/ 
/*LN-55*/         weth.transferFrom(msg.sender, address(this), amount);
/*LN-56*/ 
/*LN-57*/         playerBalances[msg.sender] += amount;
/*LN-58*/         playerSettings[msg.sender] = PlayerSettings({
/*LN-59*/             lockedAmount: amount,
/*LN-60*/             lockRecipient: msg.sender,
/*LN-61*/             lockDuration: duration,
/*LN-62*/             lockStartTime: block.timestamp
/*LN-63*/         });
/*LN-64*/ 
/*LN-65*/         emit Locked(msg.sender, amount, msg.sender);
/*LN-66*/     }
/*LN-67*/ 
/*LN-68*/     /**
/*LN-69*/      */
/*LN-70*/     function setConfigStorage(address _configStorage) external onlyAdmin {
/*LN-71*/         address oldConfig = configStorage;
/*LN-72*/         configStorage = _configStorage;
/*LN-73*/ 
/*LN-74*/         emit ConfigUpdated(oldConfig, _configStorage);
/*LN-75*/     }
/*LN-76*/ 
/*LN-77*/     function setLockRecipient(
/*LN-78*/         address player,
/*LN-79*/         address newRecipient
/*LN-80*/     ) external onlyAdmin {
/*LN-81*/ 
/*LN-82*/         playerSettings[player].lockRecipient = newRecipient;
/*LN-83*/     }
/*LN-84*/ 
/*LN-85*/     /**
/*LN-86*/      * @dev Unlock funds after lock period expires
/*LN-87*/      */
/*LN-88*/     function unlock() external {
/*LN-89*/         PlayerSettings memory settings = playerSettings[msg.sender];
/*LN-90*/ 
/*LN-91*/         require(settings.lockedAmount > 0, "No locked tokens");
/*LN-92*/         require(
/*LN-93*/             block.timestamp >= settings.lockStartTime + settings.lockDuration,
/*LN-94*/             "Still locked"
/*LN-95*/         );
/*LN-96*/ 
/*LN-97*/         uint256 amount = settings.lockedAmount;
/*LN-98*/ 
/*LN-99*/         address recipient = settings.lockRecipient;
/*LN-100*/ 
/*LN-101*/         delete playerSettings[msg.sender];
/*LN-102*/         playerBalances[msg.sender] = 0;
/*LN-103*/ 
/*LN-104*/         weth.transfer(recipient, amount);
/*LN-105*/     }
/*LN-106*/ 
/*LN-107*/     /**
/*LN-108*/      */
/*LN-109*/     function emergencyUnlock(address player) external onlyAdmin {
/*LN-110*/         PlayerSettings memory settings = playerSettings[player];
/*LN-111*/         uint256 amount = settings.lockedAmount;
/*LN-112*/         address recipient = settings.lockRecipient;
/*LN-113*/ 
/*LN-114*/         delete playerSettings[player];
/*LN-115*/         playerBalances[player] = 0;
/*LN-116*/ 
/*LN-117*/         // Sends to whoever admin set as lockRecipient
/*LN-118*/         weth.transfer(recipient, amount);
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     /**
/*LN-122*/      */
/*LN-123*/     function transferAdmin(address newAdmin) external onlyAdmin {
/*LN-124*/         admin = newAdmin;
/*LN-125*/     }
/*LN-126*/ }
/*LN-127*/ 