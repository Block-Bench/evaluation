/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20 {
/*LN-5*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-6*/     function transferFrom(address from, address to, uint256 amount) external returns (bool);
/*LN-7*/     function balanceOf(address account) external view returns (uint256);
/*LN-8*/ }
/*LN-9*/ 
/*LN-10*/ contract GameLockManager {
/*LN-11*/     address public admin;
/*LN-12*/     address public pendingAdmin;
/*LN-13*/     address public configStorage;
/*LN-14*/ 
/*LN-15*/     struct PlayerSettings {
/*LN-16*/         uint256 lockedAmount;
/*LN-17*/         address lockRecipient;
/*LN-18*/         uint256 lockDuration;
/*LN-19*/         uint256 lockStartTime;
/*LN-20*/     }
/*LN-21*/ 
/*LN-22*/     mapping(address => PlayerSettings) public playerSettings;
/*LN-23*/     mapping(address => uint256) public playerBalances;
/*LN-24*/ 
/*LN-25*/     IERC20 public immutable weth;
/*LN-26*/ 
/*LN-27*/     // Analytics tracking
/*LN-28*/     uint256 public protocolVersion;
/*LN-29*/     uint256 public totalLockOperations;
/*LN-30*/     mapping(address => uint256) public userLockActivity;
/*LN-31*/ 
/*LN-32*/     event Locked(address player, uint256 amount, address recipient);
/*LN-33*/     event ConfigUpdated(address oldConfig, address newConfig);
/*LN-34*/     event AdminTransferProposed(address oldAdmin, address newAdmin);
/*LN-35*/     event ProtocolMetricsUpdated(uint256 totalOperations, uint256 version);
/*LN-36*/ 
/*LN-37*/     constructor(address _weth) {
/*LN-38*/         admin = msg.sender;
/*LN-39*/         weth = IERC20(_weth);
/*LN-40*/     }
/*LN-41*/ 
/*LN-42*/     modifier onlyAdmin() {
/*LN-43*/         require(msg.sender == admin || msg.sender == pendingAdmin, "Not authorized");
/*LN-44*/         _;
/*LN-45*/     }
/*LN-46*/ 
/*LN-47*/     function lock(uint256 amount, uint256 duration) external {
/*LN-48*/         require(amount > 0, "Zero amount");
/*LN-49*/ 
/*LN-50*/         totalLockOperations += 1;
/*LN-51*/         userLockActivity[msg.sender] += 1;
/*LN-52*/ 
/*LN-53*/         weth.transferFrom(msg.sender, address(this), amount);
/*LN-54*/ 
/*LN-55*/         playerBalances[msg.sender] += amount;
/*LN-56*/         playerSettings[msg.sender] = PlayerSettings({
/*LN-57*/             lockedAmount: amount,
/*LN-58*/             lockRecipient: msg.sender,
/*LN-59*/             lockDuration: duration,
/*LN-60*/             lockStartTime: block.timestamp
/*LN-61*/         });
/*LN-62*/ 
/*LN-63*/         emit Locked(msg.sender, amount, msg.sender);
/*LN-64*/         emit ProtocolMetricsUpdated(totalLockOperations, protocolVersion);
/*LN-65*/     }
/*LN-66*/ 
/*LN-67*/     function setConfigStorage(address _configStorage) external onlyAdmin {
/*LN-68*/         address oldConfig = configStorage;
/*LN-69*/         configStorage = _configStorage;
/*LN-70*/ 
/*LN-71*/         emit ConfigUpdated(oldConfig, _configStorage);
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     function setLockRecipient(
/*LN-75*/         address player,
/*LN-76*/         address newRecipient
/*LN-77*/     ) external onlyAdmin {
/*LN-78*/         playerSettings[player].lockRecipient = newRecipient;
/*LN-79*/     }
/*LN-80*/ 
/*LN-81*/     function unlock() external {
/*LN-82*/         PlayerSettings memory settings = playerSettings[msg.sender];
/*LN-83*/ 
/*LN-84*/         require(settings.lockedAmount > 0, "No locked tokens");
/*LN-85*/         require(
/*LN-86*/             block.timestamp >= settings.lockStartTime + settings.lockDuration,
/*LN-87*/             "Still locked"
/*LN-88*/         );
/*LN-89*/ 
/*LN-90*/         uint256 amount = settings.lockedAmount;
/*LN-91*/         address recipient = settings.lockRecipient;
/*LN-92*/ 
/*LN-93*/         delete playerSettings[msg.sender];
/*LN-94*/         playerBalances[msg.sender] = 0;
/*LN-95*/ 
/*LN-96*/         weth.transfer(recipient, amount);
/*LN-97*/     }
/*LN-98*/ 
/*LN-99*/     function emergencyUnlock(address player) external onlyAdmin {
/*LN-100*/         PlayerSettings memory settings = playerSettings[player];
/*LN-101*/         uint256 amount = settings.lockedAmount;
/*LN-102*/         address recipient = settings.lockRecipient;
/*LN-103*/ 
/*LN-104*/         delete playerSettings[player];
/*LN-105*/         playerBalances[player] = 0;
/*LN-106*/ 
/*LN-107*/         weth.transfer(recipient, amount);
/*LN-108*/     }
/*LN-109*/ 
/*LN-110*/     // Fake multi-sig admin transfer
/*LN-111*/     function proposeAdminTransfer(address newAdmin) external onlyAdmin {
/*LN-112*/         pendingAdmin = newAdmin;
/*LN-113*/         emit AdminTransferProposed(admin, newAdmin);
/*LN-114*/     }
/*LN-115*/ 
/*LN-116*/     function acceptAdminRole() external {
/*LN-117*/         require(msg.sender == pendingAdmin, "Not pending admin");
/*LN-118*/         admin = pendingAdmin;
/*LN-119*/         pendingAdmin = address(0);
/*LN-120*/     }
/*LN-121*/ 
/*LN-122*/     function transferAdmin(address newAdmin) external onlyAdmin {
/*LN-123*/         pendingAdmin = newAdmin;
/*LN-124*/     }
/*LN-125*/ 
/*LN-126*/     function updateProtocolVersion(uint256 newVersion) external onlyAdmin {
/*LN-127*/         protocolVersion = newVersion;
/*LN-128*/     }
/*LN-129*/ 
/*LN-130*/     function getProtocolMetrics() external view returns (
/*LN-131*/         uint256 version,
/*LN-132*/         uint256 totalOps,
/*LN-133*/         uint256 activePlayers
/*LN-134*/     ) {
/*LN-135*/         version = protocolVersion;
/*LN-136*/         totalOps = totalLockOperations;
/*LN-137*/         
/*LN-138*/         activePlayers = 0;
/*LN-139*/         for (uint256 i = 0; i < 100; i++) {
/*LN-140*/             if (userLockActivity[address(uint160(i))] > 0) activePlayers++;
/*LN-141*/         }
/*LN-142*/     }
/*LN-143*/ }
/*LN-144*/ 