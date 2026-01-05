// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Dust vote on one pool prevents poke()
 * @notice VULNERABLE CONTRACT - Gold Standard Benchmark Item gs_005
 * @dev Source: CODE4RENA - 2025-10-hybra-finance
 *
 * VULNERABILITY INFORMATION:
 * - Type: dos
 * - Severity: MEDIUM
 * - Finding ID: M-04
 *
 * DESCRIPTION:
 * Before describing the vulnerability, we should know that in ve3.3 systems, `poke`
 * is important to make anyone reflect the decaying vote weight to prevent users from
 * being inactive on votes to have their full weight votes on a pool. In `VoterV3`
 * users choose what pools they want to vote for and the contract retrieves their
 * `ve` weight upon doing so: uint256 _weight =
 * IVotingEscrow(_ve).balanceOfNFT(_tokenId); And upon voting for a pool, that weight
 * affects the claimable share distribution of that pool compared to other pools.
 * Since now we know the importance of the voting weight, and since ve NFT weight
 * decay with time, there is a poke function to update the voting weight made on a
 * pool previously to the decayed weight of that NFT. The `poke()` function is
 * guarded to be called by the owner or through the `ve` contract which can have
 * anyone depositing for a user or increasing his locked value even by `1wei` to poke
 * him to reflect his new decayed weight on the voted pools. An attacker can do the
 * following: 1. vote his full weight - 1wei on a dedicated pool 2. vote 1 wei on
 * another pool 3. time passes with inactivity from his side - his ve decay but is
 * not reflected on voted pools 4. users try to poke() him through known functions of
 * the ve contract 5. poke() function reverts here File: VoterV3.sol 208: uint256
 * _poolWeight = _weights[i] * _weight / _totalVoteWeight; 209: 210:
 * require(votes[_tokenId][_pool] == 0, "ZV"); 211: require(_poolWeight != 0, "ZV");
 * Since the `1wei` vote multiplied by the decayed weight divided by totalVoteWeight
 * rounds down to 0, hence this user becomes unpokable. Impact: The voted for pool
 * will have inflated rewards distributed to him compared to other pools that have
 * pokable users. Thinking of this attack at scale, the user will have advantage of
 * having full voting weight if he votes immediately like having permanent lock
 * weight without actually locking his balance permanently. Preventing anyone from
 * preserving this invariant `A single veNFT’s total vote allocation ≤ its available
 * voting power.` on his vote balance too.
 *
 * VULNERABLE FUNCTIONS:
 * - poke()
 * - vote()
 *
 * VULNERABLE LINES:
 * - Lines: 208, 209, 210, 211
 *
 * RECOMMENDED FIX:
 * Change `require(_poolWeight != 0, "ZV")` to `if (_poolWeight == 0) continue;` to
 * skip dust votes.
 */


import './libraries/Math.sol';
import './interfaces/IBribe.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPairInfo.sol';
import './interfaces/IPairFactory.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IGaugeManager.sol';
import './interfaces/IPermissionsRegistry.sol';
import './interfaces/ITokenHandler.sol';
import {HybraTimeLibrary} from "./libraries/HybraTimeLibrary.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract VoterV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public _ve;                                         // the ve token that governs these contracts
    address internal base;                                      // $the token
    address public permissionRegistry;                          // registry to check accesses
    address public tokenHandler;                     
    uint256 public maxVotingNum;
    uint public EPOCH_DURATION;
    uint256 internal constant MIN_VOTING_NUM = 10;
    IGaugeManager public gaugeManager;
    
    mapping(uint256 => mapping(address => uint256)) public votes;  // nft      => pool     => votes
    mapping(uint256 => address[]) public poolVote;                 // nft      => pools

    mapping(address => uint256) public weights;
    uint256 public totalWeight;
    mapping(uint256 => uint256) public usedWeights;

    mapping(uint256 => uint256) public lastVoted;                     // nft      => timestamp of last vote (this is shifted to thursday of that epoc)
    mapping(uint256 => uint256) public lastVotedTimestamp;            // nft      => timestamp of last vote

    event Voted(address indexed voter, uint256 tokenId, uint256 weight);
    event Abstained(uint256 tokenId, uint256 weight);
    event SetPermissionRegistry(address indexed old, address indexed latest);

    constructor() {}

    // function initialize(address __ve, address _pairFactory, address  _gaugeFactory, address _bribes, address _tokenHandler) initializer public {
    function initialize(
        address __ve,
        address _tokenHandler,
        address _gaugeManager,
        address _permissionRegistry
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _ve = __ve;
        base = IVotingEscrow(__ve).token();
        gaugeManager = IGaugeManager(_gaugeManager);
        permissionRegistry = _permissionRegistry;
        tokenHandler = _tokenHandler;
        maxVotingNum = 30;
        EPOCH_DURATION = HybraTimeLibrary.WEEK;
    }
 
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    MODIFIERS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    modifier VoterAdmin() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("VOTER_ADMIN",msg.sender), 'VOTER_ADMIN');
        _;
    }

    modifier Governance() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("GOVERNANCE",msg.sender), 'GOVERNANCE');
        _;
    }

    modifier GenesisManager() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("GENESIS_MANAGER", msg.sender), 'GENESIS_MANAGER');
        _;
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    VoterAdmin
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

 

    /// @notice Set a new PermissionRegistry
    function setPermissionsRegistry(address _permissionRegistry) external VoterAdmin {
        require(_permissionRegistry.code.length > 0, "CODELEN");
        require(_permissionRegistry != address(0), "ZA");
        emit SetPermissionRegistry(permissionRegistry, _permissionRegistry);
        permissionRegistry = _permissionRegistry;
    }

    function setMaxVotingNum(uint256 _maxVotingNum) external VoterAdmin {
        require (_maxVotingNum >= MIN_VOTING_NUM, "LOW_VOTE");
        maxVotingNum = _maxVotingNum;
    }


    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    USER INTERACTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    
    /// @notice Reset the votes of a given TokenID
    function reset(uint256 _tokenId) external onlyNewEpoch(_tokenId) nonReentrant {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "NAO");
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint256 _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                weights[_pool] -= _votes;

                votes[_tokenId][_pool] -= _votes;
                address internal_bribe = gaugeManager.fetchInternalBribeFromPool(_pool);
                address external_bribe = gaugeManager.fetchExternalBribeFromPool(_pool);
                IBribe(internal_bribe).withdraw(uint256(_votes), _tokenId);
                IBribe(external_bribe).withdraw(uint256(_votes), _tokenId);

                // decrease totalWeight irrespective of gauge is killed/alive for this current pool
                _totalWeight += _votes;
                
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= _totalWeight;
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    /// @notice Recast the saved votes of a given TokenID
    // @audit-issue VULNERABLE FUNCTION: poke
    function poke(uint256 _tokenId) external nonReentrant {
    // ^^^ VULNERABLE LINE ^^^
        uint256 _timestamp = block.timestamp;
        // ^^^ VULNERABLE LINE ^^^
        if (_timestamp <= HybraTimeLibrary.epochVoteStart(_timestamp)){
            revert("DW");
        }
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == _ve, "NAO||VE");
        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        } 

        _vote(_tokenId, _poolVote, _weights);
    }

    
    /// @notice Vote for pools
    /// @param  _tokenId    veNFT tokenID used to vote
    /// @param  _poolVote   array of LPs addresses to vote  (eg.: [sAMM usdc-usdt   , sAMM busd-usdt, vAMM wbnb-the ,...])
    /// @param  _weights    array of weights for each LPs   (eg.: [10               , 90            , 45             ,...])  
    // @audit-issue VULNERABLE FUNCTION: vote
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) 
        external onlyNewEpoch(_tokenId) nonReentrant {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "NAO");
        require(_poolVote.length == _weights.length, "MISMATCH_LEN");
        require(_poolVote.length <= maxVotingNum, "EXCEEDS");
        uint256 _timestamp = block.timestamp;
      
        _vote(_tokenId, _poolVote, _weights);
        lastVoted[_tokenId] = HybraTimeLibrary.epochStart(block.timestamp) + 1;
        lastVotedTimestamp[_tokenId] = block.timestamp;
    }
    
    function _vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVote.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {

            if(gaugeManager.isGaugeAliveForPool(_poolVote[i])) _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];

            if (gaugeManager.isGaugeAliveForPool(_pool)) {
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;

                require(votes[_tokenId][_pool] == 0, "ZV");
                require(_poolWeight != 0, "ZV");

                poolVote[_tokenId].push(_pool);
                weights[_pool] += _poolWeight;

                votes[_tokenId][_pool] = _poolWeight;
                address internal_bribe = gaugeManager.fetchInternalBribeFromPool(_pool);
                address external_bribe = gaugeManager.fetchExternalBribeFromPool(_pool);
                
                IBribe(internal_bribe).deposit(uint256(_poolWeight), _tokenId);
                IBribe(external_bribe).deposit(uint256(_poolWeight), _tokenId);
                
                _usedWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);
        totalWeight += _usedWeight;
        usedWeights[_tokenId] = _usedWeight;
    }


    modifier onlyNewEpoch(uint256 _tokenId) {
        // ensure new epoch since last vote
        if (HybraTimeLibrary.epochStart(block.timestamp) <= lastVoted[_tokenId]) revert("VOTED");
        if (block.timestamp <= HybraTimeLibrary.epochVoteStart(block.timestamp)) revert("DW");
        _;
    }
   
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    VIEW FUNCTIONS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice view the total length of the pools
    function length() external view returns (uint256) {
        return gaugeManager.pools().length;
    }

    /// @notice view the total length of the voted pools given a tokenId
    function poolVoteLength(uint256 tokenId) external view returns(uint256) { 
        return poolVote[tokenId].length;
    }

    function setGaugeManager(address _gaugeManager) external VoterAdmin {
        require(_gaugeManager != address(0));
        gaugeManager = IGaugeManager(_gaugeManager);
    }
    
}