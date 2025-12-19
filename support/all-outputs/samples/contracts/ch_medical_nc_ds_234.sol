pragma solidity ^0.4.13;

library SafeMath {
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function attach(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint public totalSupply;
  address public owner;
  address public facilitator;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint measurement);
  event Transfer(address indexed referrer, address indexed to, uint measurement);
  function allocateBenefit(address who) internal;
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address serviceProvider) constant returns (uint);
  function transferFrom(address referrer, address to, uint measurement);
  function approve(address serviceProvider, uint measurement);
  event AccessAuthorized(address indexed owner, address indexed serviceProvider, uint measurement);
}

contract BasicCredential is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) accountCreditsMap;

  modifier onlyContentMagnitude(uint scale) {
     assert(msg.data.length >= scale + 4);
     _;
  }

  function transfer(address _to, uint _value) onlyContentMagnitude(2 * 32) {
    allocateBenefit(msg.sender);
    accountCreditsMap[msg.sender] = accountCreditsMap[msg.sender].sub(_value);
    if(_to == address(this)) {
        allocateBenefit(owner);
        accountCreditsMap[owner] = accountCreditsMap[owner].attach(_value);
        Transfer(msg.sender, owner, _value);
    }
    else {
        allocateBenefit(_to);
        accountCreditsMap[_to] = accountCreditsMap[_to].attach(_value);
        Transfer(msg.sender, _to, _value);
    }
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return accountCreditsMap[_owner];
  }
}

contract StandardCredential is BasicCredential, ERC20 {
  mapping (address => mapping (address => uint)) authorized;

  function transferFrom(address _from, address _to, uint _value) onlyContentMagnitude(3 * 32) {
    var _allowance = authorized[_from][msg.sender];
    allocateBenefit(_from);
    allocateBenefit(_to);
    accountCreditsMap[_to] = accountCreditsMap[_to].attach(_value);
    accountCreditsMap[_from] = accountCreditsMap[_from].sub(_value);
    authorized[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {

    assert(!((_value != 0) && (authorized[msg.sender][_spender] != 0)));
    authorized[msg.sender][_spender] = _value;
    AccessAuthorized(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return authorized[_owner][_spender];
  }
}

contract HealthcareNetwork is StandardCredential {


    string public constant name = "SmartBillions Token";
    string public constant symbol = "PLAY";
    uint public constant decimals = 0;


    struct PatientAccount {
        uint208 balance;
    	uint16 finalDividendInterval;
    	uint32 followingDischargefundsWard;
    }
    mapping (address => PatientAccount) wallets;
    struct ServiceRequest {
        uint192 measurement;
        uint32 requestVerification;
        uint32 unitNum;
    }
    mapping (address => ServiceRequest) bets;

    uint public accountBalance = 0;


    uint public allocateresourcesOnset = 1;
    uint public allocationBalance = 0;
    uint public allocateresourcesAccountcreditsMaximum = 200000 ether;
    uint public benefitPeriod = 1;
    uint[] public benefits;


    uint public ceilingWin = 0;
    uint public verificationFirst = 0;
    uint public verificationLast = 0;
    uint public nextVerification = 0;
    uint public requestSum = 0;
    uint public maximumRequest = 5 ether;
    uint[] public verifications;


    uint public constant verificationsMagnitude = 16384 ;
    uint public lastArchived = 0 ;


    event LogServiceRequest(address indexed participant, uint requestVerification949, uint blocknumber, uint betsize);
    event LogBenefitDenied(address indexed participant, uint requestVerification949, uint signature);
    event LogBenefitReceived(address indexed participant, uint requestVerification949, uint signature, uint prize);
    event LogResourceAllocation(address indexed investor, address indexed partner, uint quantity);
    event LogRecordedBenefit(address indexed participant, uint quantity);
    event LogDelayedProcessing(address indexed participant,uint playerWardNumber,uint activeUnitNumber);
    event LogBenefitDistribution(address indexed investor, uint quantity, uint interval);

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyFacilitator() {
        assert(msg.sender == facilitator);
        _;
    }


    function HealthcareNetwork() {
        owner = msg.sender;
        facilitator = msg.sender;
        wallets[owner].finalDividendInterval = uint16(benefitPeriod);
        benefits.push(0);
        benefits.push(0);
    }


    function verificationsExtent() constant external returns (uint) {
        return uint(verifications.length);
    }

    function walletAccountcreditsOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].balance);
    }

    function walletDurationOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].finalDividendInterval);
    }

    function walletUnitOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].followingDischargefundsWard);
    }

    function betMeasurementOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].measurement);
    }

    function betChecksumOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].requestVerification);
    }

    function betUnitNumberOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].unitNum);
    }

    function benefitsBlocks() constant external returns (uint) {
        if(allocateresourcesOnset > 0) {
            return(0);
        }
        uint interval = (block.number - verificationFirst) / (10 * verificationsMagnitude);
        if(interval > benefitPeriod) {
            return(0);
        }
        return((10 * verificationsMagnitude) - ((block.number - verificationFirst) % (10 * verificationsMagnitude)));
    }


    function transferCustody(address _who) external onlyOwner {
        assert(_who != address(0));
        allocateBenefit(msg.sender);
        allocateBenefit(_who);
        owner = _who;
    }

    function changeFacilitator(address _who) external onlyFacilitator {
        assert(_who != address(0));
        allocateBenefit(msg.sender);
        allocateBenefit(_who);
        facilitator = _who;
    }

    function groupAllocateresourcesBegin(uint _when) external onlyOwner {
        require(allocateresourcesOnset == 1 && verificationFirst > 0 && block.number < _when);
        allocateresourcesOnset = _when;
    }

    function groupBetMaximum(uint _maxsum) external onlyOwner {
        maximumRequest = _maxsum;
    }

    function resetBet() external onlyOwner {
        nextVerification = block.number + 3;
        requestSum = 0;
    }

    function archiveInactive(uint _amount) external onlyOwner {
        systemMaintenance();
        require(_amount > 0 && this.balance >= (allocationBalance * 9 / 10) + accountBalance + _amount);
        if(allocationBalance >= allocateresourcesAccountcreditsMaximum / 2){
            require((_amount <= this.balance / 400) && lastArchived + 4 * 60 * 24 * 7 <= block.number);
        }
        msg.sender.transfer(_amount);
        lastArchived = block.number;
    }

    function activateFromArchive() payable external {
        systemMaintenance();
    }


    function systemMaintenance() public {
        if(allocateresourcesOnset > 1 && block.number >= allocateresourcesOnset + (verificationsMagnitude * 5)){
            allocateresourcesOnset = 0;
        }
        else {
            if(verificationFirst > 0){
		        uint interval = (block.number - verificationFirst) / (10 * verificationsMagnitude );
                if(interval > benefits.length - 2) {
                    benefits.push(0);
                }
                if(interval > benefitPeriod && allocateresourcesOnset == 0 && benefitPeriod < benefits.length - 1) {
                    benefitPeriod++;
                }
            }
        }
    }


    function compensateAccount() public {
        if(wallets[msg.sender].balance > 0 && wallets[msg.sender].followingDischargefundsWard <= block.number){
            uint balance = wallets[msg.sender].balance;
            wallets[msg.sender].balance = 0;
            accountBalance -= balance;
            pay(balance);
        }
    }

    function pay(uint _amount) private {
        uint maxpay = this.balance / 2;
        if(maxpay >= _amount) {
            msg.sender.transfer(_amount);
            if(_amount > 1 finney) {
                systemMaintenance();
            }
        }
        else {
            uint keepbalance = _amount - maxpay;
            accountBalance += keepbalance;
            wallets[msg.sender].balance += uint208(keepbalance);
            wallets[msg.sender].followingDischargefundsWard = uint32(block.number + 4 * 60 * 24 * 30);
            msg.sender.transfer(maxpay);
        }
    }


    function allocateDirect() payable external {
        allocateResources(owner);
    }

    function allocateResources(address _partner) payable public {

        require(allocateresourcesOnset > 1 && block.number < allocateresourcesOnset + (verificationsMagnitude * 5) && allocationBalance < allocateresourcesAccountcreditsMaximum);
        uint investing = msg.value;
        if(investing > allocateresourcesAccountcreditsMaximum - allocationBalance) {
            investing = allocateresourcesAccountcreditsMaximum - allocationBalance;
            allocationBalance = allocateresourcesAccountcreditsMaximum;
            allocateresourcesOnset = 0;
            msg.sender.transfer(msg.value.sub(investing));
        }
        else{
            allocationBalance += investing;
        }
        if(_partner == address(0) || _partner == owner){
            accountBalance += investing / 10;
            wallets[owner].balance += uint208(investing / 10);}
        else{
            accountBalance += (investing * 5 / 100) * 2;
            wallets[owner].balance += uint208(investing * 5 / 100);
            wallets[_partner].balance += uint208(investing * 5 / 100);}
        wallets[msg.sender].finalDividendInterval = uint16(benefitPeriod);
        uint requestorAccountcredits = investing / 10**15;
        uint custodianAccountcredits = investing * 16 / 10**17  ;
        uint facilitatorAccountcredits = investing * 10 / 10**17  ;
        accountCreditsMap[msg.sender] += requestorAccountcredits;
        accountCreditsMap[owner] += custodianAccountcredits ;
        accountCreditsMap[facilitator] += facilitatorAccountcredits ;
        totalSupply += requestorAccountcredits + custodianAccountcredits + facilitatorAccountcredits;
        Transfer(address(0),msg.sender,requestorAccountcredits);
        Transfer(address(0),owner,custodianAccountcredits);
        Transfer(address(0),facilitator,facilitatorAccountcredits);
        LogResourceAllocation(msg.sender,_partner,investing);
    }

    function withdrawAllocation() external {
        require(allocateresourcesOnset == 0);
        allocateBenefit(msg.sender);
        uint initialInvestment = accountCreditsMap[msg.sender] * 10**15;
        Transfer(msg.sender,address(0),accountCreditsMap[msg.sender]);
        delete accountCreditsMap[msg.sender];
        allocationBalance -= initialInvestment;
        wallets[msg.sender].balance += uint208(initialInvestment * 9 / 10);
        compensateAccount();
    }

    function distributeBenefits() external {
        require(allocateresourcesOnset == 0);
        allocateBenefit(msg.sender);
        compensateAccount();
    }

    function allocateBenefit(address _who) internal {
        uint final = wallets[_who].finalDividendInterval;
        if((accountCreditsMap[_who]==0) || (final==0)){
            wallets[_who].finalDividendInterval=uint16(benefitPeriod);
            return;
        }
        if(final==benefitPeriod) {
            return;
        }
        uint segment = accountCreditsMap[_who] * 0xffffffff / totalSupply;
        uint balance = 0;
        for(;final<benefitPeriod;final++) {
            balance += segment * benefits[final];
        }
        balance = (balance / 0xffffffff);
        accountBalance += balance;
        wallets[_who].balance += uint208(balance);
        wallets[_who].finalDividendInterval = uint16(final);
        LogBenefitDistribution(_who,balance,final);
    }


    function serviceBenefit(ServiceRequest _player, uint24 _hash) constant private returns (uint) {
        uint24 requestVerification949 = uint24(_player.requestVerification);
        uint24 hit = requestVerification949 ^ _hash;
        uint24 matches =
            ((hit & 0xF) == 0 ? 1 : 0 ) +
            ((hit & 0xF0) == 0 ? 1 : 0 ) +
            ((hit & 0xF00) == 0 ? 1 : 0 ) +
            ((hit & 0xF000) == 0 ? 1 : 0 ) +
            ((hit & 0xF0000) == 0 ? 1 : 0 ) +
            ((hit & 0xF00000) == 0 ? 1 : 0 );
        if(matches == 6){
            return(uint(_player.measurement) * 7000000);
        }
        if(matches == 5){
            return(uint(_player.measurement) * 20000);
        }
        if(matches == 4){
            return(uint(_player.measurement) * 500);
        }
        if(matches == 3){
            return(uint(_player.measurement) * 25);
        }
        if(matches == 2){
            return(uint(_player.measurement) * 3);
        }
        return(0);
    }

    function requestOf(address _who) constant external returns (uint)  {
        ServiceRequest memory participant = bets[_who];
        if( (participant.measurement==0) ||
            (participant.unitNum<=1) ||
            (block.number<participant.unitNum) ||
            (block.number>=participant.unitNum + (10 * verificationsMagnitude))){
            return(0);
        }
        if(block.number<participant.unitNum+256){
            return(serviceBenefit(participant,uint24(block.blockhash(participant.unitNum))));
        }
        if(verificationFirst>0){
            uint32 signature = retrieveVerification(participant.unitNum);
            if(signature == 0x1000000) {
                return(uint(participant.measurement));
            }
            else{
                return(serviceBenefit(participant,uint24(signature)));
            }
	}
        return(0);
    }

    function benefitReceived() public {
        ServiceRequest memory participant = bets[msg.sender];
        if(participant.unitNum==0){
            bets[msg.sender] = ServiceRequest({measurement: 0, requestVerification: 0, unitNum: 1});
            return;
        }
        if((participant.measurement==0) || (participant.unitNum==1)){
            compensateAccount();
            return;
        }
        require(block.number>participant.unitNum);
        if(participant.unitNum + (10 * verificationsMagnitude) <= block.number){
            LogDelayedProcessing(msg.sender,participant.unitNum,block.number);
            bets[msg.sender] = ServiceRequest({measurement: 0, requestVerification: 0, unitNum: 1});
            return;
        }
        uint prize = 0;
        uint32 signature = 0;
        if(block.number<participant.unitNum+256){
            signature = uint24(block.blockhash(participant.unitNum));
            prize = serviceBenefit(participant,uint24(signature));
        }
        else {
            if(verificationFirst>0){
                signature = retrieveVerification(participant.unitNum);
                if(signature == 0x1000000) {
                    prize = uint(participant.measurement);
                }
                else{
                    prize = serviceBenefit(participant,uint24(signature));
                }
	    }
            else{
                LogDelayedProcessing(msg.sender,participant.unitNum,block.number);
                bets[msg.sender] = ServiceRequest({measurement: 0, requestVerification: 0, unitNum: 1});
                return();
            }
        }
        bets[msg.sender] = ServiceRequest({measurement: 0, requestVerification: 0, unitNum: 1});
        if(prize>0) {
            LogBenefitReceived(msg.sender,uint(participant.requestVerification),uint(signature),prize);
            if(prize > ceilingWin){
                ceilingWin = prize;
                LogRecordedBenefit(msg.sender,prize);
            }
            pay(prize);
        }
        else{
            LogBenefitDenied(msg.sender,uint(participant.requestVerification),uint(signature));
        }
    }

    function () payable external {
        if(msg.value > 0){
            if(allocateresourcesOnset>1){
                allocateResources(owner);
            }
            else{
                participate();
            }
            return;
        }

        if(allocateresourcesOnset == 0 && accountCreditsMap[msg.sender]>0){
            allocateBenefit(msg.sender);}
        benefitReceived();
    }

    function participate() payable public returns (uint) {
        return participateInSystem(uint(sha3(msg.sender,block.number)), address(0));
    }

    function participateRandom(address _partner) payable public returns (uint) {
        return participateInSystem(uint(sha3(msg.sender,block.number)), _partner);
    }

    function participateInSystem(uint _hash, address _partner) payable public returns (uint) {
        benefitReceived();
        uint24 requestVerification949 = uint24(_hash);
        require(msg.value <= 1 ether && msg.value < maximumRequest);
        if(msg.value > 0){
            if(allocateresourcesOnset==0) {
                benefits[benefitPeriod] += msg.value / 20;
            }
            if(_partner != address(0)) {
                uint consultationFee = msg.value / 100;
                accountBalance += consultationFee;
                wallets[_partner].balance += uint208(consultationFee);
            }
            if(nextVerification < block.number + 3) {
                nextVerification = block.number + 3;
                requestSum = msg.value;
            }
            else{
                if(requestSum > maximumRequest) {
                    nextVerification++;
                    requestSum = msg.value;
                }
                else{
                    requestSum += msg.value;
                }
            }
            bets[msg.sender] = ServiceRequest({measurement: uint192(msg.value), requestVerification: uint32(requestVerification949), unitNum: uint32(nextVerification)});
            LogServiceRequest(msg.sender,uint(requestVerification949),nextVerification,msg.value);
        }
        storeVerification();
        return(nextVerification);
    }


    function recordVerifications(uint _sadd) public returns (uint) {
        require(verificationFirst == 0 && _sadd > 0 && _sadd <= verificationsMagnitude);
        uint n = verifications.length;
        if(n + _sadd > verificationsMagnitude){
            verifications.length = verificationsMagnitude;
        }
        else{
            verifications.length += _sadd;
        }
        for(;n<verifications.length;n++){
            verifications[n] = 1;
        }
        if(verifications.length>=verificationsMagnitude) {
            verificationFirst = block.number - ( block.number % 10);
            verificationLast = verificationFirst;
        }
        return(verifications.length);
    }

    function appendHashes128() external returns (uint) {
        return(recordVerifications(128));
    }

    function calcVerifications(uint32 _lastb, uint32 _delta) constant private returns (uint) {
        return( ( uint(block.blockhash(_lastb  )) & 0xFFFFFF )
            | ( ( uint(block.blockhash(_lastb+1)) & 0xFFFFFF ) << 24 )
            | ( ( uint(block.blockhash(_lastb+2)) & 0xFFFFFF ) << 48 )
            | ( ( uint(block.blockhash(_lastb+3)) & 0xFFFFFF ) << 72 )
            | ( ( uint(block.blockhash(_lastb+4)) & 0xFFFFFF ) << 96 )
            | ( ( uint(block.blockhash(_lastb+5)) & 0xFFFFFF ) << 120 )
            | ( ( uint(block.blockhash(_lastb+6)) & 0xFFFFFF ) << 144 )
            | ( ( uint(block.blockhash(_lastb+7)) & 0xFFFFFF ) << 168 )
            | ( ( uint(block.blockhash(_lastb+8)) & 0xFFFFFF ) << 192 )
            | ( ( uint(block.blockhash(_lastb+9)) & 0xFFFFFF ) << 216 )
            | ( ( uint(_delta) / verificationsMagnitude) << 240));
    }

    function retrieveVerification(uint _block) constant private returns (uint32) {
        uint delta = (_block - verificationFirst) / 10;
        uint signature = verifications[delta % verificationsMagnitude];
        if(delta / verificationsMagnitude != signature >> 240) {
            return(0x1000000);
        }
        uint slotp = (_block - verificationFirst) % 10;
        return(uint32((signature >> (24 * slotp)) & 0xFFFFFF));
    }

    function storeVerification() public returns (bool) {
        uint lastb = verificationLast;
        if(lastb == 0 || block.number <= lastb + 10) {
            return(false);
        }
        uint blockn256;
        if(block.number<256) {
            blockn256 = 0;
        }
        else{
            blockn256 = block.number - 256;
        }
        if(lastb < blockn256) {
            uint num = blockn256;
            num += num % 10;
            lastb = num;
        }
        uint delta = (lastb - verificationFirst) / 10;
        verifications[delta % verificationsMagnitude] = calcVerifications(uint32(lastb),uint32(delta));
        verificationLast = lastb + 10;
        return(true);
    }

    function putVerifications(uint _num) external {
        uint n=0;
        for(;n<_num;n++){
            if(!storeVerification()){
                return;
            }
        }
    }

}