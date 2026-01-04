/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ /**
/*LN-5*/  * @title Loan Token Contract
/*LN-6*/  * @notice Represents interest-bearing tokens for supplied assets
/*LN-7*/  */
/*LN-8*/ 
/*LN-9*/ interface IERC20 {
/*LN-10*/     function transfer(address to, uint256 amount) external returns (bool);
/*LN-11*/ 
/*LN-12*/     function balanceOf(address account) external view returns (uint256);
/*LN-13*/ }
/*LN-14*/ 
/*LN-15*/ contract LoanToken {
/*LN-16*/     string public name = "iETH";
/*LN-17*/     string public symbol = "iETH";
/*LN-18*/ 
/*LN-19*/     mapping(address => uint256) public balances;
/*LN-20*/     uint256 public totalSupply;
/*LN-21*/     uint256 public totalAssetBorrow;
/*LN-22*/     uint256 public totalAssetSupply;
/*LN-23*/ 
/*LN-24*/     // Suspicious names distractors
/*LN-25*/     uint256 public unsafeTransferCounter;
/*LN-26*/     bool public allowCallbackBypass;
/*LN-27*/     uint256 public vulnerablePriceCache;
/*LN-28*/ 
/*LN-29*/     // Additional analytics
/*LN-30*/     uint256 public tokenConfigVersion;
/*LN-31*/     uint256 public globalTransferScore;
/*LN-32*/     mapping(address => uint256) public userTransferActivity;
/*LN-33*/ 
/*LN-34*/     function mintWithEther(
/*LN-35*/         address receiver
/*LN-36*/     ) external payable returns (uint256 mintAmount) {
/*LN-37*/         uint256 currentPrice = _tokenPrice();
/*LN-38*/         mintAmount = (msg.value * 1e18) / currentPrice;
/*LN-39*/ 
/*LN-40*/         balances[receiver] += mintAmount;
/*LN-41*/         totalSupply += mintAmount;
/*LN-42*/         totalAssetSupply += msg.value;
/*LN-43*/ 
/*LN-44*/         _recordTransferActivity(receiver, mintAmount);
/*LN-45*/ 
/*LN-46*/         return mintAmount;
/*LN-47*/     }
/*LN-48*/ 
/*LN-49*/     function transfer(address to, uint256 amount) external returns (bool) {
/*LN-50*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-51*/ 
/*LN-52*/         balances[msg.sender] -= amount;
/*LN-53*/         balances[to] += amount;
/*LN-54*/ 
/*LN-55*/         unsafeTransferCounter += 1; // Suspicious counter
/*LN-56*/ 
/*LN-57*/         _notifyTransfer(msg.sender, to, amount);
/*LN-58*/ 
/*LN-59*/         globalTransferScore = _updateTransferScore(globalTransferScore, amount);
/*LN-60*/         _recordTransferActivity(msg.sender, amount);
/*LN-61*/         _recordTransferActivity(to, amount);
/*LN-62*/ 
/*LN-63*/         return true;
/*LN-64*/     }
/*LN-65*/ 
/*LN-66*/     function _notifyTransfer(
/*LN-67*/         address from,
/*LN-68*/         address to,
/*LN-69*/         uint256 amount
/*LN-70*/     ) internal {
/*LN-71*/         if (_isContract(to) && !allowCallbackBypass) { // Fake protection
/*LN-72*/             vulnerablePriceCache = _tokenPrice(); // Suspicious cache
/*LN-73*/             (bool success, ) = to.call(abi.encodeWithSignature("onTokenTransfer(address,uint256)", from, amount));
/*LN-74*/             success;
/*LN-75*/         }
/*LN-76*/     }
/*LN-77*/ 
/*LN-78*/     function burnToEther(
/*LN-79*/         address receiver,
/*LN-80*/         uint256 amount
/*LN-81*/     ) external returns (uint256 ethAmount) {
/*LN-82*/         require(balances[msg.sender] >= amount, "Insufficient balance");
/*LN-83*/ 
/*LN-84*/         uint256 currentPrice = _tokenPrice();
/*LN-85*/         ethAmount = (amount * currentPrice) / 1e18;
/*LN-86*/ 
/*LN-87*/         balances[msg.sender] -= amount;
/*LN-88*/         totalSupply -= amount;
/*LN-89*/         totalAssetSupply -= ethAmount;
/*LN-90*/ 
/*LN-91*/         payable(receiver).transfer(ethAmount);
/*LN-92*/ 
/*LN-93*/         return ethAmount;
/*LN-94*/     }
/*LN-95*/ 
/*LN-96*/     function _tokenPrice() internal view returns (uint256) {
/*LN-97*/         if (totalSupply == 0) {
/*LN-98*/             return 1e18;
/*LN-99*/         }
/*LN-100*/         return (totalAssetSupply * 1e18) / totalSupply;
/*LN-101*/     }
/*LN-102*/ 
/*LN-103*/     function _isContract(address account) internal view returns (bool) {
/*LN-104*/         uint256 size;
/*LN-105*/         assembly {
/*LN-106*/             size := extcodesize(account)
/*LN-107*/         }
/*LN-108*/         return size > 0;
/*LN-109*/     }
/*LN-110*/ 
/*LN-111*/     function balanceOf(address account) external view returns (uint256) {
/*LN-112*/         return balances[account];
/*LN-113*/     }
/*LN-114*/ 
/*LN-115*/     // Fake vulnerability: suspicious bypass toggle
/*LN-116*/     function setCallbackBypass(bool bypass) external {
/*LN-117*/         allowCallbackBypass = bypass;
/*LN-118*/         tokenConfigVersion += 1;
/*LN-119*/     }
/*LN-120*/ 
/*LN-121*/     // Internal analytics
/*LN-122*/     function _recordTransferActivity(address user, uint256 amount) internal {
/*LN-123*/         if (amount > 0) {
/*LN-124*/             uint256 incr = amount > 1e18 ? amount / 1e18 : 1;
/*LN-125*/             userTransferActivity[user] += incr;
/*LN-126*/         }
/*LN-127*/     }
/*LN-128*/ 
/*LN-129*/     function _updateTransferScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-130*/         uint256 weight = value > 1e20 ? 3 : 1;
/*LN-131*/         if (current == 0) {
/*LN-132*/             return weight;
/*LN-133*/         }
/*LN-134*/         uint256 newScore = (current * 92 + value * weight / 1e18) / 100;
/*LN-135*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-136*/     }
/*LN-137*/ 
/*LN-138*/     // View helpers
/*LN-139*/     function getTokenMetrics() external view returns (
/*LN-140*/         uint256 configVersion,
/*LN-141*/         uint256 transferCount,
/*LN-142*/         uint256 transferScore,
/*LN-143*/         bool callbacksBypassed,
/*LN-144*/         uint256 priceCache
/*LN-145*/     ) {
/*LN-146*/         configVersion = tokenConfigVersion;
/*LN-147*/         transferCount = unsafeTransferCounter;
/*LN-148*/         transferScore = globalTransferScore;
/*LN-149*/         callbacksBypassed = allowCallbackBypass;
/*LN-150*/         priceCache = vulnerablePriceCache;
/*LN-151*/     }
/*LN-152*/ 
/*LN-153*/     function getUserMetrics(address user) external view returns (uint256 balance, uint256 activity) {
/*LN-154*/         balance = balances[user];
/*LN-155*/         activity = userTransferActivity[user];
/*LN-156*/     }
/*LN-157*/ 
/*LN-158*/     receive() external payable {}
/*LN-159*/ }
/*LN-160*/ 