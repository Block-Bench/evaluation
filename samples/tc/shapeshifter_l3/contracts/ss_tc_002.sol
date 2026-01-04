/*LN-1*/ pragma solidity ^0.8.0;
/*LN-2*/ interface IDiamondCut {
/*LN-3*/     struct FacetCut {
/*LN-4*/         address _0x347a3f;
/*LN-5*/         uint8 _0xd860ea;
/*LN-6*/         bytes4[] _0x390062;
/*LN-7*/     }
/*LN-8*/ }
/*LN-9*/ contract Governance {
/*LN-10*/     mapping(address => uint256) public _0x8cd0a4;
/*LN-11*/     mapping(address => uint256) public _0x2c833f;
/*LN-12*/     struct Proposal {
/*LN-13*/         address _0x0d961f;
/*LN-14*/         address _0x0353ce;
/*LN-15*/         bytes data;
/*LN-16*/         uint256 _0x65ce0c;
/*LN-17*/         uint256 _0x0f4194;
/*LN-18*/         bool _0x6ff151;
/*LN-19*/     }
/*LN-20*/     mapping(uint256 => Proposal) public _0x2ff8d2;
/*LN-21*/     mapping(uint256 => mapping(address => bool)) public _0x771f54;
/*LN-22*/     uint256 public _0x477183;
/*LN-23*/     uint256 public _0x0cce35;
/*LN-24*/     uint256 constant EMERGENCY_THRESHOLD = 66;
/*LN-25*/     event ProposalCreated(
/*LN-26*/         uint256 indexed _0xd80623,
/*LN-27*/         address _0x0d961f,
/*LN-28*/         address _0x0353ce
/*LN-29*/     );
/*LN-30*/     event Voted(uint256 indexed _0xd80623, address _0xae3550, uint256 _0x8e4527);
/*LN-31*/     event ProposalExecuted(uint256 indexed _0xd80623);
/*LN-32*/     function _0xd6cb4d(uint256 _0x51bedd) external {
/*LN-33*/         _0x8cd0a4[msg.sender] += _0x51bedd;
/*LN-34*/         _0x2c833f[msg.sender] += _0x51bedd;
/*LN-35*/         _0x0cce35 += _0x51bedd;
/*LN-36*/     }
/*LN-37*/     function _0xe5feba(
/*LN-38*/         IDiamondCut.FacetCut[] calldata,
/*LN-39*/         address _0x8e6f03,
/*LN-40*/         bytes calldata _0x1045d1,
/*LN-41*/         uint8
/*LN-42*/     ) external returns (uint256) {
/*LN-43*/         _0x477183++;
/*LN-44*/         Proposal storage _0x4f9b02 = _0x2ff8d2[_0x477183];
/*LN-45*/         _0x4f9b02._0x0d961f = msg.sender;
/*LN-46*/         _0x4f9b02._0x0353ce = _0x8e6f03;
/*LN-47*/         _0x4f9b02.data = _0x1045d1;
/*LN-48*/         _0x4f9b02._0x0f4194 = block.timestamp;
/*LN-49*/         _0x4f9b02._0x6ff151 = false;
/*LN-50*/         _0x4f9b02._0x65ce0c = _0x2c833f[msg.sender];
/*LN-51*/         _0x771f54[_0x477183][msg.sender] = true;
/*LN-52*/         emit ProposalCreated(_0x477183, msg.sender, _0x8e6f03);
/*LN-53*/         return _0x477183;
/*LN-54*/     }
/*LN-55*/     function _0x6e3d9a(uint256 _0xd80623) external {
/*LN-56*/         require(!_0x771f54[_0xd80623][msg.sender], "Already voted");
/*LN-57*/         require(!_0x2ff8d2[_0xd80623]._0x6ff151, "Already executed");
/*LN-58*/         _0x2ff8d2[_0xd80623]._0x65ce0c += _0x2c833f[msg.sender];
/*LN-59*/         _0x771f54[_0xd80623][msg.sender] = true;
/*LN-60*/         emit Voted(_0xd80623, msg.sender, _0x2c833f[msg.sender]);
/*LN-61*/     }
/*LN-62*/     function _0x7d6277(uint256 _0xd80623) external {
/*LN-63*/         Proposal storage _0x4f9b02 = _0x2ff8d2[_0xd80623];
/*LN-64*/         require(!_0x4f9b02._0x6ff151, "Already executed");
/*LN-65*/         uint256 _0x7248ad = (_0x4f9b02._0x65ce0c * 100) / _0x0cce35;
/*LN-66*/         require(_0x7248ad >= EMERGENCY_THRESHOLD, "Insufficient votes");
/*LN-67*/         _0x4f9b02._0x6ff151 = true;
/*LN-68*/         (bool _0x70dd97, ) = _0x4f9b02._0x0353ce.call(_0x4f9b02.data);
/*LN-69*/         require(_0x70dd97, "Execution failed");
/*LN-70*/         emit ProposalExecuted(_0xd80623);
/*LN-71*/     }
/*LN-72*/ }