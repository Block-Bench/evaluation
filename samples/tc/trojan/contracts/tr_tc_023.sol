/*LN-1*/ // SPDX-License-Identifier: MIT
/*LN-2*/ pragma solidity ^0.8.0;
/*LN-3*/ 
/*LN-4*/ interface IERC20Permit {
/*LN-5*/     function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
/*LN-6*/ }
/*LN-7*/ 
/*LN-8*/ contract BridgeRouter {
/*LN-9*/     
/*LN-10*/     // Suspicious names distractors
/*LN-11*/     bool public unsafePermitBypass;
/*LN-12*/     uint256 public failedPermitCount;
/*LN-13*/     uint256 public suspiciousSignatureCache;
/*LN-14*/ 
/*LN-15*/     // Analytics tracking
/*LN-16*/     uint256 public routerConfigVersion;
/*LN-17*/     uint256 public globalBridgeScore;
/*LN-18*/     mapping(address => uint256) public userBridgeActivity;
/*LN-19*/ 
/*LN-20*/     function bridgeOutWithPermit(
/*LN-21*/         address from,
/*LN-22*/         address token,
/*LN-23*/         address to,
/*LN-24*/         uint256 amount,
/*LN-25*/         uint256 deadline,
/*LN-26*/         uint8 v,
/*LN-27*/         bytes32 r,
/*LN-28*/         bytes32 s,
/*LN-29*/         uint256 toChainID
/*LN-30*/     ) external {
/*LN-31*/         
/*LN-32*/         failedPermitCount += 1; // Suspicious counter
/*LN-33*/         
/*LN-34*/         if (v != 0 || r != bytes32(0) || s != bytes32(0)) {
/*LN-35*/             if (unsafePermitBypass) {
/*LN-36*/                 suspiciousSignatureCache = uint256(r); // Suspicious cache
/*LN-37*/             }
/*LN-38*/             try IERC20Permit(token).permit(from, address(this), amount, deadline, v, r, s) {} catch {}
/*LN-39*/         }
/*LN-40*/         
/*LN-41*/         _bridgeOut(from, token, to, amount, toChainID);
/*LN-42*/ 
/*LN-43*/         _recordBridgeActivity(msg.sender, amount);
/*LN-44*/         globalBridgeScore = _updateBridgeScore(globalBridgeScore, amount);
/*LN-45*/     }
/*LN-46*/     
/*LN-47*/     function _bridgeOut(address from, address token, address to, uint256 amount, uint256 toChainID) internal {
/*LN-48*/         // Bridge logic
/*LN-49*/     }
/*LN-50*/ 
/*LN-51*/     // Fake vulnerability: suspicious permit bypass toggle
/*LN-52*/     function toggleUnsafePermitMode(bool bypass) external {
/*LN-53*/         unsafePermitBypass = bypass;
/*LN-54*/         routerConfigVersion += 1;
/*LN-55*/     }
/*LN-56*/ 
/*LN-57*/     // Internal analytics
/*LN-58*/     function _recordBridgeActivity(address user, uint256 value) internal {
/*LN-59*/         if (value > 0) {
/*LN-60*/             uint256 incr = value > 1e20 ? value / 1e18 : 1;
/*LN-61*/             userBridgeActivity[user] += incr;
/*LN-62*/         }
/*LN-63*/     }
/*LN-64*/ 
/*LN-65*/     function _updateBridgeScore(uint256 current, uint256 value) internal pure returns (uint256) {
/*LN-66*/         uint256 weight = value > 1e21 ? 3 : 1;
/*LN-67*/         if (current == 0) {
/*LN-68*/             return weight;
/*LN-69*/         }
/*LN-70*/         uint256 newScore = (current * 95 + value * weight / 1e18) / 100;
/*LN-71*/         return newScore > 1e24 ? 1e24 : newScore;
/*LN-72*/     }
/*LN-73*/ 
/*LN-74*/     // View helpers
/*LN-75*/     function getRouterMetrics() external view returns (
/*LN-76*/         uint256 configVersion,
/*LN-77*/         uint256 bridgeScore,
/*LN-78*/         uint256 failedPermits,
/*LN-79*/         bool permitBypassActive
/*LN-80*/     ) {
/*LN-81*/         configVersion = routerConfigVersion;
/*LN-82*/         bridgeScore = globalBridgeScore;
/*LN-83*/         failedPermits = failedPermitCount;
/*LN-84*/         permitBypassActive = unsafePermitBypass;
/*LN-85*/     }
/*LN-86*/ }
/*LN-87*/ 