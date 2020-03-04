pragma solidity ^0.5.8;

contract TokenAuction {
    uint durationTime;
    address owner;
    mapping (address => uint) tokenBalances;
    uint public initialSupply;
    uint rateOfTokensToGivePerEth;

    event Auction(address tokenHolder, uint cost, uint tokenBalance);

    constructor() public payable {
        durationTime = now + 1 minutes;
        owner = msg.sender;
        initialSupply = 1000;
        tokenBalances[owner] = initialSupply;
        rateOfTokensToGivePerEth = 10;
    }

    modifier timeCheck() {
        require(durationTime >= now, "Auction Time is Over");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Auction Owner is authorized");
        _;
    }

    function buyTokens() public payable timeCheck {
        uint tokens = rateOfTokensToGivePerEth * (msg.value / 1 ether);
        require(tokens <= initialSupply, "Token Underflow");
        require(tokenBalances[msg.sender] + tokens >= tokenBalances[msg.sender], "Token Overflow");
        tokenBalances[owner] -= tokens;
        tokenBalances[msg.sender] += tokens;

        emit Auction(msg.sender, msg.value, tokenBalances[msg.sender]);
    }

    function getBalance() public view returns (uint tokens) {
        return tokenBalances[msg.sender];
    }

    function currentSupply() public view onlyOwner returns (uint tokensLeft) {
        return tokenBalances[owner];
    }

    function auctionBalance() public view onlyOwner returns (uint profits) {
        return address(this).balance;
    }

}
