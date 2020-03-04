pragma solidity >=0.4.22 <0.6.2;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function tokenBalance(address who) public view returns (uint256);
    function transfer(address to, uint256 value) internal returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LemonToken is ERC20Basic {

    address payable owner;
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public initialSupply;
    uint256 tokenSupply;

    mapping (address => uint) balances;

    constructor() public {
        owner = msg.sender;
        name = "LemonToken";
        symbol = "LMN";
        decimals = 18;
        initialSupply = 1000000;
        tokenSupply = initialSupply;
        balances[owner] = tokenSupply;
    }

    function totalSupply() public view returns (uint256 tokens) {
        return balances[owner];
    }

    function tokenBalance(address _owner) public view returns (uint256 LMNtokens) {
        return balances[_owner];
    }

    function transfer(address to, uint256 value) internal returns (bool success) {
        balances[owner] = tokenSupply;
        if (balances[owner] >= value && value > 0) {
            balances[owner] -= value;
            balances[to] += value;
            emit Transfer(owner, to, value);
            return true;
        } else { return false; }
    }

}

contract LemonCrowdsale is LemonToken {

    uint startTime;
    uint endTime;
    uint rateOfTokensToGivePerEth;
    address payable walletToStoreTheEthers;
    uint lemonTokens;
    mapping (address => uint) contribution;

    constructor() public payable {
        walletToStoreTheEthers = msg.sender;
        startTime = now + 2 minutes;
        endTime = startTime + 5 minutes;
        rateOfTokensToGivePerEth = 10;
        contribution[msg.sender] = 0;
    }

    modifier hasBegun() {
        require(startTime <= now, "ICO Launch has not begun");
        _;
    }

    modifier timedICO() {
        require(!hasEnded(), "Crowdsale has ended!");
        _;
    }

    modifier nonOwner() {
        require(walletToStoreTheEthers != msg.sender, "Contract Owner cannot partake in ICO");
        _;
    }

    function hasEnded() public view returns (bool icoEnded) {
        return endTime <= now;
    }

    function ownerBalance() public view returns (uint weiProfits) {
        require(walletToStoreTheEthers == msg.sender, "Only Contract Owner is authorized");
        return contribution[msg.sender];
    }

    function contributions() public view nonOwner returns (uint weiContributions) {
        return contribution[msg.sender];
    }

    function buyLemonTokens() public payable hasBegun timedICO nonOwner {
        lemonTokens = rateOfTokensToGivePerEth * (msg.value / 1 ether);
        require(msg.value > 0, "Cannot buy ZERO tokens");
        contribution[walletToStoreTheEthers] += msg.value;
        contribution[msg.sender] += msg.value;
        LemonToken.transfer(msg.sender, lemonTokens);
        walletToStoreTheEthers.transfer(msg.value);
    }
}
