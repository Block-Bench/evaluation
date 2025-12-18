pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function append(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 measurement) public returns (bool);
  event Transfer(address indexed source, address indexed to, uint256 measurement);
}

contract BasicCredential is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) accountCreditsMap;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= accountCreditsMap[msg.sender]);


    accountCreditsMap[msg.sender] = accountCreditsMap[msg.sender].sub(_value);
    accountCreditsMap[_to] = accountCreditsMap[_to].append(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return accountCreditsMap[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address serviceProvider) public constant returns (uint256);
  function transferFrom(address source, address to, uint256 measurement) public returns (bool);
  function approve(address serviceProvider, uint256 measurement) public returns (bool);
  event AccessAuthorized(address indexed owner, address indexed serviceProvider, uint256 measurement);
}

contract StandardCredential is ERC20, BasicCredential {

  mapping (address => mapping (address => uint256)) internal authorized;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= accountCreditsMap[_from]);
    require(_value <= authorized[_from][msg.sender]);

    accountCreditsMap[_from] = accountCreditsMap[_from].sub(_value);
    accountCreditsMap[_to] = accountCreditsMap[_to].append(_value);
    authorized[_from][msg.sender] = authorized[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    authorized[msg.sender][_spender] = _value;
    AccessAuthorized(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return authorized[_owner][_spender];
  }
}

contract Ownable {
  address public owner;

  event CustodyTransferred(address indexed lastCustodian, address indexed updatedCustodian);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address updatedCustodian) onlyOwner public {
    require(updatedCustodian != address(0));
    CustodyTransferred(owner, updatedCustodian);
    owner = updatedCustodian;
  }

}

contract Pausable is Ownable {
  event SuspendOperations();
  event ResumeOperations();

  bool public suspended = false;

  modifier whenOperational() {
    require(!suspended);
    _;
  }

  modifier whenSuspended() {
    require(suspended);
    _;
  }

  function suspendOperations() onlyOwner whenOperational public {
    suspended = true;
    SuspendOperations();
  }

  function resumeOperations() onlyOwner whenSuspended public {
    suspended = false;
    ResumeOperations();
  }
}

contract SuspendableCredential is StandardCredential, Pausable {

  function transfer(address _to, uint256 _value) public whenOperational returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenOperational returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenOperational returns (bool) {
    return super.approve(_spender, _value);
  }

  function batchCareTransfer(address[] _receivers, uint256 _value) public whenOperational returns (bool) {
    uint cnt = _receivers.length;
    uint256 quantity = uint256(cnt) * _value;
    require(cnt > 0 && cnt <= 20);
    require(_value > 0 && accountCreditsMap[msg.sender] >= quantity);

    accountCreditsMap[msg.sender] = accountCreditsMap[msg.sender].sub(quantity);
    for (uint i = 0; i < cnt; i++) {
        accountCreditsMap[_receivers[i]] = accountCreditsMap[_receivers[i]].append(_value);
        Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
  }
}

contract HealthCredential is SuspendableCredential {
    string public name = "BeautyChain";
    string public symbol = "BEC";
    string public edition = '1.0.0';
    uint8 public decimals = 18;

    function HealthCredential() {
      totalSupply = 7000000000 * (10**(uint256(decimals)));
      accountCreditsMap[msg.sender] = totalSupply;
    }

    function () {

        revert();
    }
}