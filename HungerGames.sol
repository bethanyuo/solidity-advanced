pragma solidity ^0.5.0;

import "github.com/provable-things/ethereum-api/provableAPI.sol"; // Must use Injected Web3


contract HungerGames is usingProvable {

    uint startTime;
    uint durationTime;
    uint public randomNumber;
    bool hasStarted = false;
    string[] private nameIndex;
    mapping (string => Tribute) private Tributes;

    event generatedRandomNumber(uint256 randomNumber);
    event selectedTributes(string maleTribute, string femTribute);
    event allTributes(string gender, uint age, bool isAlive);
    uint public modulus;

    string[] private boyList;
    string[] private girlList;

    struct Tribute {
        string name;
        string gender;
        uint age;
        bool isAlive;
        uint index;
        uint genderIndex;
    }


    constructor() public payable {
        provable_setProof(proofType_Ledger);
    }

    modifier gameTime() {
        hasStarted = true;
        startTime = block.timestamp;
        durationTime = startTime + 5 minutes;
        _;
    }

    modifier beforeGame() {
        require(!hasStarted, "The Hunger Games has already begun");
        _;
    }

    modifier afterGame() {
        require(hasStarted && durationTime <= block.timestamp, "The Hunger Games is not Over yet");
        _;
    }

    function isTribute(string memory name)
    internal
    returns(bool)
    {
        if(nameIndex.length == 0) return false;

        return keccak256(bytes(name)) == keccak256(bytes(nameIndex[Tributes[name].index]));
    }

    function addTributes(string memory name, string memory gender, uint age) public beforeGame returns(uint index) {
        require(!isTribute(name), "Will not allow duplicates");
        require(age >= 12 && age <= 18, "Unqualifiable age");
        Tributes[name].gender   = gender;
        Tributes[name].age      = age;
        Tributes[name].isAlive  = true;
        Tributes[name].index    = nameIndex.push(name)-1;

        if (keccak256(bytes(gender)) == keccak256(bytes("male"))) {
            Tributes[name].genderIndex = boyList.push(name)-1;
        } else {
            require(keccak256(bytes(gender)) == keccak256(bytes("female")), "Unspecified Gender");
            Tributes[name].genderIndex = girlList.push(name)-1;
        }

        return nameIndex.push(name)-1;
    }

    function getMaleTributes() public view returns (uint) {
        return boyList.length;
    }

    function getFemaleTributes() public view returns (uint) {
        return girlList.length;
    }

    function selectTributes() public gameTime {
        emit selectedTributes(boyList[randomNumber], girlList[randomNumber]);
    }

    function randSelector() internal returns(bool) {
        if (randomNumber % 2 == 0) {
            Tributes[boyList[randomNumber]].isAlive = false;
        } else {
            Tributes[girlList[randomNumber]].isAlive = false;
        }
        return true;
    }

    function allSurviving(string memory name) public afterGame {
        require(isTribute(name), "Person requested is not Tribute");
        randSelector();
        emit allTributes(Tributes[name].gender, Tributes[name].age, Tributes[name].isAlive);
    }

    function __callback(bytes32 queryId, string memory result, bytes memory proof) public {
        require(msg.sender == provable_cbAddress());

        if(provable_randomDS_proofVerify__returnCode(queryId, result, proof) == 0) {
            uint maxRange = boyList.length - 1;
            randomNumber = uint(keccak256(abi.encodePacked(result))) % maxRange;
            emit generatedRandomNumber(randomNumber);
        } else {
            // Proof verification failed
        }
    }

    function getRandomNumber() public beforeGame payable {
        require(boyList.length == girlList.length && boyList.length != 0, "Teams must be of equal size");
        uint numberOfBytes = 4;
        uint delay = 0;
        uint callbackGas = 200000;
        bytes32 queryId = provable_newRandomDSQuery(delay, numberOfBytes, callbackGas);
    }
}
