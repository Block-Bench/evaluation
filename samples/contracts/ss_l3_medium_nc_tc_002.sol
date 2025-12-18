pragma solidity ^0.8.0;


interface IDiamondCut {
    struct FacetCut {
        address _0x42a41e;
        uint8 _0x3b39df;
        bytes4[] _0x207d78;
    }
}

contract GovernanceSystem {

    mapping(address => uint256) public _0x955283;
    mapping(address => uint256) public _0x40e319;


    struct Proposal {
        address _0x300a2a;
        address _0x9d24aa;
        bytes data;
        uint256 _0x0d6d5f;
        uint256 _0x863929;
        bool _0x2c5e65;
    }

    mapping(uint256 => Proposal) public _0x599771;
    mapping(uint256 => mapping(address => bool)) public _0x49932a;
    uint256 public _0xda9242;

    uint256 public _0x005c2b;


    uint256 constant EMERGENCY_THRESHOLD = 66;

    event ProposalCreated(
        uint256 indexed _0x8ed553,
        address _0x300a2a,
        address _0x9d24aa
    );
    event Voted(uint256 indexed _0x8ed553, address _0x2b1c7c, uint256 _0x078715);
    event ProposalExecuted(uint256 indexed _0x8ed553);


    function _0x039865(uint256 _0xe1d9b3) external {
        _0x955283[msg.sender] += _0xe1d9b3;
        _0x40e319[msg.sender] += _0xe1d9b3;
        _0x005c2b += _0xe1d9b3;
    }


    function _0x433dcd(
        IDiamondCut.FacetCut[] calldata,
        address _0xfad5c6,
        bytes calldata _0x6889a5,
        uint8
    ) external returns (uint256) {
        _0xda9242++;

        Proposal storage _0xb2aac1 = _0x599771[_0xda9242];
        _0xb2aac1._0x300a2a = msg.sender;
        _0xb2aac1._0x9d24aa = _0xfad5c6;
        _0xb2aac1.data = _0x6889a5;
        _0xb2aac1._0x863929 = block.timestamp;
        _0xb2aac1._0x2c5e65 = false;


        _0xb2aac1._0x0d6d5f = _0x40e319[msg.sender];
        _0x49932a[_0xda9242][msg.sender] = true;

        emit ProposalCreated(_0xda9242, msg.sender, _0xfad5c6);
        return _0xda9242;
    }


    function _0x6e352e(uint256 _0x8ed553) external {
        require(!_0x49932a[_0x8ed553][msg.sender], "Already voted");
        require(!_0x599771[_0x8ed553]._0x2c5e65, "Already executed");

        _0x599771[_0x8ed553]._0x0d6d5f += _0x40e319[msg.sender];
        _0x49932a[_0x8ed553][msg.sender] = true;

        emit Voted(_0x8ed553, msg.sender, _0x40e319[msg.sender]);
    }


    function _0xb3df1c(uint256 _0x8ed553) external {
        Proposal storage _0xb2aac1 = _0x599771[_0x8ed553];
        require(!_0xb2aac1._0x2c5e65, "Already executed");

        uint256 _0x62ad92 = (_0xb2aac1._0x0d6d5f * 100) / _0x005c2b;
        require(_0x62ad92 >= EMERGENCY_THRESHOLD, "Insufficient votes");

        _0xb2aac1._0x2c5e65 = true;


        (bool _0xdf51c0, ) = _0xb2aac1._0x9d24aa.call(_0xb2aac1.data);
        require(_0xdf51c0, "Execution failed");

        emit ProposalExecuted(_0x8ed553);
    }
}