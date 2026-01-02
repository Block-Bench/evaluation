/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(
/*LN-7*/         address from,
/*LN-8*/         address to,
/*LN-9*/         uint256 amount
/*LN-10*/     ) external returns (bool);
/*LN-11*/     function balanceOf(address account) external view returns (uint256);
/*LN-12*/ }
/*LN-13*/ 
/*LN-14*/ contract MunchablesLockManager {
/*LN-15*/     address public admin;
/*LN-16*/     address public configStorage;
/*LN-17*/     address public pendingAdmin;
/*LN-18*/     uint256 public adminTransferTime;
/*LN-19*/     uint256 public constant ADMIN_TRANSFER_DELAY = 48 hours;
/*LN-20*/ 
/*LN-21*/     struct PlayerSettings {
/*LN-22*/         uint256 lockedAmount;
/*LN-23*/         address lockRecipient;
/*LN-24*/         uint256 lockDuration;
/*LN-25*/         uint256 lockStartTime;
/*LN-26*/     }
/*LN-27*/ 
/*LN-28*/     mapping(address => PlayerSettings) public playerSettings;
/*LN-29*/     mapping(address => uint256) public playerBalances;
/*LN-30*/ 
/*LN-31*/     IERC20 public immutable weth;
/*LN-32*/ 
/*LN-33*/     event Locked(address player, uint256 amount, address recipient);
/*LN-34*/     event ConfigUpdated(address oldConfig, address newConfig);
/*LN-35*/     event AdminTransferInitiated(address indexed newAdmin, uint256 executeAfter);
/*LN-36*/     event AdminTransferCompleted(address indexed oldAdmin, address indexed newAdmin);
/*LN-37*/ 
/*LN-38*/     constructor(address _weth) {
/*LN-39*/         admin = msg.sender;
/*LN-40*/         weth = IERC20(_weth);
/*LN-41*/     }
/*LN-42*/ 
/*LN-43*/     modifier onlyAdmin() {
/*LN-44*/         require(msg.sender == admin, "Not admin");
/*LN-45*/         _;
/*LN-46*/     }
/*LN-47*/ 
/*LN-48*/     function lock(uint256 amount, uint256 duration) external {
/*LN-49*/         require(amount > 0, "Zero amount");
/*LN-50*/ 
/*LN-51*/         weth.transferFrom(msg.sender, address(this), amount);
/*LN-52*/ 
/*LN-53*/         playerBalances[msg.sender] += amount;
/*LN-54*/         playerSettings[msg.sender] = PlayerSettings({
/*LN-55*/             lockedAmount: amount,
/*LN-56*/             lockRecipient: msg.sender,
/*LN-57*/             lockDuration: duration,
/*LN-58*/             lockStartTime: block.timestamp
/*LN-59*/         });
/*LN-60*/ 
/*LN-61*/         emit Locked(msg.sender, amount, msg.sender);
/*LN-62*/     }
/*LN-63*/ 
/*LN-64*/     function setConfigStorage(address _configStorage) external onlyAdmin {
/*LN-65*/         address oldConfig = configStorage;
/*LN-66*/         configStorage = _configStorage;
/*LN-67*/ 
/*LN-68*/         emit ConfigUpdated(oldConfig, _configStorage);
/*LN-69*/     }
/*LN-70*/ 
/*LN-71*/     function setLockRecipient(
/*LN-72*/         address newRecipient
/*LN-73*/     ) external {
/*LN-74*/         require(newRecipient != address(0), "Invalid recipient");
/*LN-75*/         playerSettings[msg.sender].lockRecipient = newRecipient;
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function unlock() external {
/*LN-79*/         PlayerSettings memory settings = playerSettings[msg.sender];
/*LN-80*/ 
/*LN-81*/         require(settings.lockedAmount > 0, "No locked tokens");
/*LN-82*/         require(
/*LN-83*/             block.timestamp >= settings.lockStartTime + settings.lockDuration,
/*LN-84*/             "Still locked"
/*LN-85*/         );
/*LN-86*/ 
/*LN-87*/         uint256 amount = settings.lockedAmount;
/*LN-88*/ 
/*LN-89*/         address recipient = settings.lockRecipient;
/*LN-90*/ 
/*LN-91*/         delete playerSettings[msg.sender];
/*LN-92*/         playerBalances[msg.sender] = 0;
/*LN-93*/ 
/*LN-94*/         weth.transfer(recipient, amount);
/*LN-95*/     }
/*LN-96*/ 
/*LN-97*/     function emergencyUnlock(address player) external onlyAdmin {
/*LN-98*/         PlayerSettings memory settings = playerSettings[player];
/*LN-99*/         uint256 amount = settings.lockedAmount;
/*LN-100*/         address recipient = settings.lockRecipient;
/*LN-101*/ 
/*LN-102*/         delete playerSettings[player];
/*LN-103*/         playerBalances[player] = 0;
/*LN-104*/ 
/*LN-105*/         weth.transfer(recipient, amount);
/*LN-106*/     }
/*LN-107*/ 
/*LN-108*/     function initiateAdminTransfer(address newAdmin) external onlyAdmin {
/*LN-109*/         require(newAdmin != address(0), "Invalid admin");
/*LN-110*/         pendingAdmin = newAdmin;
/*LN-111*/         adminTransferTime = block.timestamp + ADMIN_TRANSFER_DELAY;
/*LN-112*/         emit AdminTransferInitiated(newAdmin, adminTransferTime);
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     function completeAdminTransfer() external onlyAdmin {
/*LN-116*/         require(pendingAdmin != address(0), "No pending transfer");
/*LN-117*/         require(block.timestamp >= adminTransferTime, "Timelock not expired");
/*LN-118*/ 
/*LN-119*/         address oldAdmin = admin;
/*LN-120*/         admin = pendingAdmin;
/*LN-121*/         pendingAdmin = address(0);
/*LN-122*/         adminTransferTime = 0;
/*LN-123*/ 
/*LN-124*/         emit AdminTransferCompleted(oldAdmin, admin);
/*LN-125*/     }
/*LN-126*/ 
/*LN-127*/     function cancelAdminTransfer() external onlyAdmin {
/*LN-128*/         pendingAdmin = address(0);
/*LN-129*/         adminTransferTime = 0;
/*LN-130*/     }
/*LN-131*/ }
/*LN-132*/ 