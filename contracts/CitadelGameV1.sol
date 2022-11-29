// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPILOT {
    function getOnchainPILOT(uint256 tokenId) external view returns (bool, uint8);
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CitadelGameV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IPILOT public immutable pilotCollection;

    // data structures
    struct CitadelStaked {
        address walletAddress;
        uint256 gridId;
        uint8 factionId;
        uint256 timeOfLastClaim;
        uint256 timeOfLastRaid;
        uint256[] pilot;
        bool isLit;
        bool isOnline;
        uint256 timeWentOffline;
        uint8 shieldPower;
    }

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
        bool isValue;
    }

    struct Raid {
        uint256 toCitadel;
        Fleet fleet;
        uint256[] pilot;
        bool isValue;
        uint256 timeRaidHits;
    }

    // mappings
    mapping(uint256 => CitadelStaked) public citadel; // index is _citadelId
    mapping(uint256 => Fleet) public fleet; // index is _citadelId
    mapping(uint256 => Raid) public raids; // index is _fromCitadelId

    // citadel props
    uint8[] public shieldProp = [0,1,1,1,0,0,1,3,0,1,2,0,1,0,0,0,0,0,0,1,2,0,0,0,0,1,1,1,0,0,3,0,0,1,0,1,0,1,0,0,1,0,1,0,0,0,3,2,2,2,1,2,1,3,0,0,2,0,2,0,3,0,0,0,2,0,0,2,3,0,1,1,0,1,0,0,1,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,3,0,0,2,0,0,1,0,1,0,2,2,1,2,1,0,1,1,0,0,0,2,0,0,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,1,0,2,0,6,4,0,0,2,1,4,2,0,0,0,1,0,2,0,0,0,0,2,0,3,1,0,0,1,0,0,2,1,0,0,0,0,0,1,0,1,0,0,3,1,0,2,0,1,0,0,0,2,0,2,4,0,0,0,0,1,0,0,0,3,0,1,3,0,1,0,1,1,2,0,0,1,1,1,0,2,0,0,0,0,0,2,0,1,0,2,3,1,2,1,0,1,0,2,0,1,1,1,0,1,0,0,1,1,0,0,0,2,2,3,1,1,3,0,0,0,0,2,0,1,0,1,1,1,1,3,0,1,1,0,6,2,0,3,0,1,1,1,1,1,0,2,2,2,1,0,1,0,0,0,2,0,0,0,1,0,3,0,3,2,2,0,0,0,0,0,1,0,0,0,0,2,1,0,1,0,1,0,1,4,0,0,1,0,0,0,1,2,0,0,2,2,1,1,2,0,1,2,3,0,4,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,1,2,0,0,2,0,1,1,0,3,0,0,3,0,1,0,0,0,2,0,0,0,4,1,1,1,4,0,0,0,2,1,0,0,0,0,0,0,1,0,3,0,0,0,1,0,1,0,0,6,1,2,0,0,2,0,4,5,1,2,0,0,0,1,2,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,1,1,2,2,2,1,1,4,1,0,2,0,2,1,0,0,0,0,0,0,1,0,0,0,0,3,0,0,0,7,1,2,2,0,1,0,5,0,0,0,1,1,2,0,0,0,1,0,0,1,2,0,1,0,0,0,1,0,1,0,1,3,0,0,1,0,0,0,2,2,1,0,0,0,0,3,3,1,0,2,0,2,0,2,0,5,1,0,0,4,0,0,5,0,1,3,0,1,4,0,0,2,1,2,2,0,0,0,0,1,0,0,0,0,0,1,4,1,0,0,1,0,0,0,5,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,1,1,0,0,2,3,1,0,1,2,1,5,0,0,0,0,0,0,1,6,2,0,2,1,0,3,0,0,2,1,0,3,0,2,3,0,1,0,3,0,0,1,0,2,3,1,1,3,1,1,0,1,1,3,0,0,1,0,1,0,0,3,0,2,0,1,0,0,0,0,1,1,0,0,1,1,2,1,0,0,3,1,0,2,1,0,0,3,0,0,2,0,0,0,1,2,0,2,0,0,2,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1,1,2,0,1,3,1,2,0,0,1,3,0,0,0,0,0,1,2,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,2,0,0,3,1,0,0,0,1,1,2,2,1,0,0,3,0,0,0,2,0,1,0,0,0,1,2,0,2,6,0,0,0,0,2,0,3,1,0,1,1,3,0,0,2,0,0,2,1,0,0,0,1,0,1,1,5,0,0,1,4,2,0,0,1,2,1,0,2,1,1,2,0,0,0,2,0,2,1,0,0,0,0,2,1,0,1,1,1,3,1,0,2,2,3,0,0,1,0,0,0,1,0,1,4,2,1,3,1,0,1,0,1,0,0,6,1,0,3,0,0,1,2,1,0,0,0,0,0,0,2,3,2,0,1,0,1,1,0,0,1,2,2,2,0,0,0,4,0,0,0,3,1,4,1,2,1,5,4,0,0,0,2,1,1,0,0,0,1,2,5,2,0,0,0,0,0,0,3,1,1,3,1,0,0,0,1,0,1,0,3,0,0,2,1,0,1,0,1,0,0,1,0,0,1,0,0,0,3,2,0,1,3,3,0,1,0,1,0,1,0,0,0,1,0,2,0,4,1,0,2,3,1,1,0,1,0,0,6,0,0,3,2,2,0,0,0,0,0,0,0,0,0,0,0,3,2,0,2,0,0,0,0,0,0,2,3,2,3,3,4,3,4,7,5,3,4,4,6,5,4,5,4,4,4,4,4,5,4,4,4,7,4,5,5,5,7];
    uint8[] public engineProp = [1,0,1,4,1,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,1,0,3,0,0,0,0,1,1,0,3,1,1,0,1,0,0,0,0,1,0,3,0,1,0,0,3,0,0,3,1,0,0,0,2,0,1,1,0,1,0,0,0,0,0,0,1,7,0,2,1,3,0,0,5,1,0,0,1,0,0,1,1,1,0,0,0,0,1,0,0,3,1,2,0,0,4,0,1,0,3,2,0,0,0,0,0,1,0,0,0,0,0,0,0,3,2,1,0,0,2,0,2,0,1,0,1,0,1,1,0,5,1,0,3,1,0,0,3,0,1,1,1,1,0,0,6,1,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,2,0,0,0,4,0,2,0,5,5,0,2,6,3,0,0,1,0,0,4,0,1,2,1,1,2,1,0,0,2,7,2,0,2,0,2,0,0,1,0,2,5,0,1,4,0,0,0,0,0,1,1,2,1,0,2,1,0,4,1,4,0,1,2,2,0,0,1,0,0,0,0,1,0,2,1,1,0,4,0,1,1,2,1,1,0,1,0,1,0,1,2,3,0,0,0,0,1,3,1,0,2,0,2,0,3,0,0,1,0,6,0,0,1,0,0,2,1,0,0,1,1,0,1,2,1,1,1,1,0,0,0,0,4,0,2,0,1,1,5,0,1,2,2,3,2,2,0,3,1,5,1,1,0,0,1,1,3,2,0,0,0,0,0,0,0,0,0,0,3,0,0,0,2,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,1,2,0,1,0,2,1,0,2,3,0,2,0,0,0,1,0,0,4,1,0,0,0,4,0,0,0,4,4,1,5,0,0,1,2,1,1,1,0,2,1,1,1,3,2,0,2,0,0,1,0,0,0,0,0,1,2,0,3,1,0,3,0,0,0,0,0,1,1,0,0,1,1,1,0,0,0,1,0,2,0,1,2,0,1,1,0,0,0,2,0,1,0,2,1,2,1,0,1,0,3,0,2,0,1,3,1,0,0,0,0,1,3,0,0,1,0,1,4,1,0,1,0,1,1,1,2,0,0,0,3,1,1,2,1,2,0,2,2,4,0,0,2,3,2,0,0,0,0,0,2,1,0,4,1,1,0,0,0,0,0,2,0,0,0,0,1,1,1,0,0,0,1,3,1,0,1,3,1,0,4,2,1,0,0,1,1,0,1,1,0,2,0,2,0,2,2,0,1,0,0,0,0,1,2,0,0,2,2,1,1,1,2,0,5,0,0,0,0,0,1,0,1,0,0,1,2,0,2,4,5,1,0,2,0,0,0,4,0,6,3,2,2,0,1,0,1,4,0,0,1,0,0,0,0,1,1,0,0,1,1,0,0,3,0,0,3,1,1,0,0,2,0,2,1,2,0,3,0,1,0,2,1,0,0,4,3,2,0,1,2,0,1,0,0,4,0,2,0,3,3,0,1,0,0,0,1,1,0,2,0,3,1,0,0,1,0,3,1,4,0,3,0,0,4,1,1,1,0,0,3,0,0,0,0,2,0,0,0,4,1,0,0,0,0,0,2,1,3,0,0,0,0,2,0,0,0,2,1,0,3,0,0,1,0,1,0,2,0,0,0,0,1,0,1,1,1,5,5,2,0,2,0,0,0,0,0,1,3,1,0,1,0,2,0,0,0,2,1,2,1,2,2,0,5,1,1,0,0,3,2,0,1,0,0,1,0,2,1,0,3,0,0,3,2,1,1,1,2,0,0,0,1,0,1,2,0,1,2,0,0,1,0,1,3,2,5,0,0,0,0,0,3,2,0,0,4,1,1,0,0,3,0,2,0,0,0,1,2,2,0,1,2,1,2,0,6,0,1,0,1,2,2,2,0,2,0,0,0,3,4,1,1,1,1,4,0,0,2,2,0,2,2,0,1,0,0,0,1,1,0,3,1,0,3,0,3,2,2,0,1,0,1,5,1,0,0,3,0,0,2,0,0,1,4,1,1,1,0,1,0,0,3,0,0,3,1,0,0,0,1,2,0,0,0,0,0,2,2,0,0,0,0,0,4,5,4,2,0,1,0,1,2,0,2,0,2,0,1,0,0,1,1,2,0,0,0,0,2,1,1,0,2,0,0,0,0,0,0,1,0,1,0,0,1,0,0,3,0,4,1,1,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,3,0,0,0,0,0,0,0,3,3,3,6,6,6,7,7];
    uint8[] public weaponsProp = [0,0,0,1,1,3,0,0,1,3,1,0,0,0,4,4,2,4,0,0,1,1,4,0,0,5,0,1,0,0,0,3,0,0,1,0,0,1,0,0,2,1,0,0,0,0,1,0,3,0,1,0,1,3,0,0,1,1,2,1,0,2,0,0,0,2,1,0,1,1,1,0,0,2,1,2,3,0,0,2,2,0,0,2,0,0,0,3,0,0,0,0,0,0,1,1,1,0,0,0,1,5,0,1,4,0,1,0,3,0,0,0,0,1,0,1,0,0,0,0,3,1,1,1,0,0,2,0,0,5,0,1,1,1,0,0,1,4,1,0,0,1,0,1,0,0,0,1,1,2,0,2,3,0,3,0,3,1,6,2,1,1,0,0,0,0,1,0,1,0,2,2,0,0,0,1,1,0,0,1,0,0,1,0,0,0,4,5,1,0,1,1,1,0,0,0,2,5,0,1,0,0,1,0,2,0,0,3,0,0,1,2,0,2,0,0,0,0,0,2,3,1,1,1,0,0,5,1,0,0,0,0,1,2,2,1,0,0,3,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,1,0,0,2,0,0,2,1,2,0,1,0,0,5,1,0,2,2,1,2,0,1,3,0,1,2,0,0,1,0,0,2,2,0,1,0,0,1,4,1,0,1,2,0,0,4,0,0,4,0,1,0,1,0,0,1,2,0,1,0,1,3,0,0,1,0,0,1,1,0,1,0,0,0,0,3,1,1,0,1,4,1,0,3,0,0,1,0,0,2,1,5,1,4,2,2,1,2,0,0,1,1,1,0,0,3,0,0,0,2,1,1,2,0,0,1,4,0,1,1,0,2,0,0,0,0,4,2,0,0,1,0,0,0,4,0,0,0,1,1,4,3,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,1,0,1,4,0,0,2,0,0,0,7,1,0,3,5,1,4,1,0,0,2,1,1,1,0,0,1,4,0,6,1,1,1,1,0,0,3,0,4,3,4,0,1,0,1,0,0,0,3,2,3,2,2,2,0,0,2,1,0,2,1,1,0,1,0,0,2,1,0,0,4,1,0,2,0,2,2,0,2,4,0,0,0,1,1,1,0,1,0,2,0,0,0,1,0,1,1,0,0,0,4,1,1,0,0,0,1,2,0,4,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,2,0,3,0,2,0,1,0,2,2,0,0,0,0,0,2,0,0,1,1,0,0,7,0,1,2,2,0,1,2,2,0,2,0,0,1,1,1,0,2,1,0,1,4,0,0,1,0,0,2,1,2,0,0,4,1,0,0,1,2,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,1,0,2,0,0,0,0,3,1,2,3,0,0,0,0,1,0,2,1,2,0,2,1,1,0,1,2,0,0,5,2,2,5,0,0,0,0,1,7,1,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,1,0,1,1,0,0,2,2,0,1,1,1,0,0,2,1,2,0,1,0,2,0,0,2,3,0,0,2,3,3,0,1,4,0,1,0,0,1,0,0,3,0,4,0,1,0,0,0,0,0,0,1,3,0,4,1,1,0,0,0,0,1,2,1,1,1,1,0,0,2,2,4,1,0,1,0,2,0,0,1,1,0,2,1,4,0,0,0,0,1,0,2,0,0,2,1,0,0,1,1,2,0,2,1,0,5,0,0,0,1,0,0,2,2,1,0,0,1,1,2,0,0,0,2,0,5,0,0,2,5,0,0,0,0,0,7,0,2,0,3,0,0,0,3,2,0,2,0,1,2,0,1,0,0,0,0,0,2,3,1,1,0,0,0,1,0,2,0,1,3,1,0,0,1,0,0,0,0,0,0,0,3,0,2,0,0,0,0,2,2,0,0,1,1,0,0,2,1,0,0,1,0,0,0,0,2,5,0,1,0,2,1,0,0,1,3,0,0,0,0,1,3,0,0,1,0,1,0,0,0,1,0,1,0,0,0,2,0,1,1,0,0,0,2,0,0,0,0,0,1,2,2,1,0,0,0,0,0,3,0,2,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,2,1,1,0,0,6,0,1,2,3,0,0,1,2,1,0,2,0,1,0,2,0,0,1,2,0,2,0,0,0,0,0,0,0,0,3,1,3,3,1,3,2,3,3,3,3,6,5,6,3,3,3,3,3,3,3,6,3,3,3,3,3,3,6,6];

    //variables
    uint256 public baseMiningRatePerHour = 20000000000000000000; //20 DK base / hr
    uint256 public periodFinish = 1674943200; //JAN 28 2023, 2PM PT 
    uint256 public maxGrid = 1000;
    uint8 public maxFaction = 5;
    uint256 public sifGattacaPrice = 100000000000000000000;
    uint256 public mhrudvogThrotPrice = 100000000000000000000;
    uint256 public drebentraakhtPrice = 1000000000000000000000;
    uint8 public pilotMultiple = 25;
    uint8 public levelMultiple = 5;
    uint256 public multipleDivisor = 100;
    bool public subgridOpen = false;
    uint256 public minFleet = 500;

    constructor(IERC721 _citadelCollection, IPILOT _pilotCollection, IERC20 _drakma) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
    }

    // external functions
    function liteGrid(uint256 _citadelId, uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel to stake"
        );
        require(citadel[_citadelId].isLit == false, "grid cannot be lit");
        require(_gridId <= maxGrid, "invalid grid");
        require(_factionId <= maxFaction, "invalid faction");

        citadelCollection.transferFrom(msg.sender, address(this), _citadelId);

        citadel[_citadelId].walletAddress = msg.sender;
        citadel[_citadelId].gridId = _gridId;
        citadel[_citadelId].factionId = _factionId;
        citadel[_citadelId].timeOfLastClaim = lastTimeRewardApplicable();
        citadel[_citadelId].timeOfLastRaid = lastTimeRewardApplicable();
        citadel[_citadelId].isLit = true;
        citadel[_citadelId].isOnline = true;
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId] = Fleet(0,0,0,true);
        }

        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                "must own pilot to stake"
            );
            pilotCollection.transferFrom(msg.sender, address(this), _pilotIds[i]);
            citadel[_citadelId].pilot.push(_pilotIds[i]);
        }
    }

    function dimGrid(uint256 _citadelId) external nonReentrant {
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own lit citadel to withdraw"
        );

        claimInternal(_citadelId);
        for (uint256 i; i < citadel[_citadelId].pilot.length; ++i) {
            pilotCollection.transferFrom(address(this), msg.sender, citadel[_citadelId].pilot[i]);
        }
        citadelCollection.transferFrom(address(this), msg.sender, _citadelId);

        citadel[_citadelId].walletAddress = 0x0000000000000000000000000000000000000000;
        citadel[_citadelId].gridId = 0;
        citadel[_citadelId].factionId = 0;
        citadel[_citadelId].timeOfLastClaim = 0;
        citadel[_citadelId].timeOfLastRaid = 0;
        citadel[_citadelId].isLit = false;
        citadel[_citadelId].isOnline = false;
    }

    function claim(uint256 _citadelId) external nonReentrant {
        claimInternal(_citadelId);
    }

    function trainFleet(uint256 sifGattaca, uint256 mhrudvogThrot, uint256 drebentraakht) external nonReentrant returns (uint256) {
        uint256 timeTrainingDone = 0;

        return timeTrainingDone;
    }

    function sendRaid(uint256 _fromCitadel, uint256 _toCitadel, uint256[] calldata pilot, uint256 sifGattaca, uint256 drebentraakht) external nonReentrant returns (uint256) {
        require(_fromCitadel != _toCitadel, "cannot raid own citadel");
        require(
            citadel[_fromCitadel].walletAddress == msg.sender,
            "must own lit citadel to raid"
        );
        require(
            citadel[_fromCitadel].isLit == true && citadel[_fromCitadel].isOnline == true,
            "attacking citadel must be lit and online to raid"
        );
        require(
            citadel[_toCitadel].isLit == true && citadel[_toCitadel].isOnline == true,
            "defending citadel must be lit and online to raid"
        );
        require(
            raids[_fromCitadel].isValue == false,
            "raids must resolve before another can be sent"
        );
        require(
            sifGattaca <= fleet[_fromCitadel].sifGattaca && drebentraakht <= fleet[_fromCitadel].drebentraakht,
            "cannot send more fleet than are trained"
        );
        require(
            sifGattaca + drebentraakht >= minFleet,
            "fleet sent in raid must exceed minimum for raiding"
        );

        for (uint256 i; i < pilot.length; ++i) {
            bool pilotFound = false;
            for (uint256 j; j < citadel[_fromCitadel].pilot.length; ++j) {
                if(pilot[i] == citadel[_fromCitadel].pilot[j]) {
                    pilotFound = true;
                    break;
                }
            }
            require(pilotFound == true, "pilot sent must be staked to raiding citadel");
        }

        // raids immediate when subgrid open
        uint256 timeRaidHits = lastTimeRewardApplicable();
        uint256 gridDistance = calculateGridDistance(citadel[_fromCitadel].gridId, citadel[_toCitadel].gridId);
        timeRaidHits += (gridDistance * 3600000);

        //Fleet sentFleet = Fleet(sifGattaca, 0, drebentraakht, true);
        raids[_fromCitadel] = Raid(_toCitadel, Fleet(sifGattaca, 0, drebentraakht, true), pilot, true, timeRaidHits);
        fleet[_fromCitadel].sifGattaca -= sifGattaca;
        fleet[_fromCitadel].drebentraakht -= drebentraakht;
        citadel[_fromCitadel].isOnline = false;
        citadel[_toCitadel].isOnline = false;
        citadel[_fromCitadel].timeWentOffline = timeRaidHits;
        citadel[_toCitadel].timeWentOffline = timeRaidHits;

        if (gridDistance == 0 || subgridOpen == true) {
            resolveRaidInternal(_fromCitadel);
            return timeRaidHits;
        }

        return timeRaidHits;
    }

    // public functions
    function resolveRaid(uint256 _fromCitadel) external nonReentrant {
        require(
            citadel[_fromCitadel].isOnline == true,
            "citadel does not require raid resolution"
        );

        resolveRaidInternal(_fromCitadel);
    }

    // internal functions
    function resolveRaidInternal(uint256 _fromCitadel) internal {

    }

    function claimInternal(uint256 _citadelId) internal {
        require(citadel[_citadelId].timeOfLastClaim > 0, "cannot claim unlit citadel");
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel to claim"
        );
        uint256 minedDrakma = calculateMiningOutput(_citadelId, citadel[_citadelId].gridId);
        require(minedDrakma > 0, "you have no drakma mined");
        drakma.safeTransfer(msg.sender, minedDrakma);
        citadel[_citadelId].timeOfLastClaim = lastTimeRewardApplicable();
    }

    // only owner
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }

    // internal views
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function calculateBaseCitadelMultiple(uint8 index) internal view returns (uint256) {
        if (index == 0) {
            return 10;
        } else if (index == 1) {
            return 11;
        } else if (index == 2) {
            return 12;
        } else if (index == 3) {
            return 15;
        } else if (index == 4) {
            return 17;
        } else if (index == 5) {
            return 20;
        } else if (index == 6) {
            return 25;
        } else {
            return 35;
        }
    }

    function calculateUniqueBonus(uint8 weapon, uint8 engine, uint8 shield) internal view returns (uint256, uint256) {
        uint256 swarmMultiple = 0;
        uint256 siegeMultiple = 0;
        if (weapon == 0) {
            swarmMultiple += 5;
        } else if (weapon == 1) {
            siegeMultiple += 5;
        } else if (weapon == 2) {
            swarmMultiple += 6;
        } else if (weapon == 3) {
            swarmMultiple += 7;
        } else if (weapon == 4) {
            siegeMultiple += 7;
        } else if (weapon == 6) {
            swarmMultiple += 10;
        }

        if (shield == 0) {
            siegeMultiple += 5;
        } else if (shield == 1) {
            siegeMultiple += 10;
        } else if (shield == 2) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (shield == 3) {
            siegeMultiple += 15;
        } else if (shield == 4) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        } else if (shield == 5) {
            swarmMultiple += 15;
        } else {
            swarmMultiple += 25;
        }

        if (engine == 0) {
            swarmMultiple += 1;
            siegeMultiple += 1;
        } else if (engine == 1) {
            swarmMultiple += 2;
            siegeMultiple += 2;
        } else if (engine == 5) {
            swarmMultiple += 5;
            siegeMultiple += 5;
        }
        
        return (swarmMultiple, siegeMultiple);
    }

    function calculateMinintMultiple(uint8 engine, uint8 shield) internal view returns (uint256) {
        uint256 multiple = 0;
        if (shield == 6) {
            multiple += 5;
        }

        if (engine == 3) {
            multiple += 1;
        } else if (engine == 7) {
            multiple += 5;
        }

        return multiple;
    }

    // public views
    function calculateMiningOutput(uint256 _citadelId, uint256 _gridId) public view returns (uint256) {
        uint256 miningMultiple = calculateMinintMultiple(engineProp[_citadelId], shieldProp[_citadelId]);
        return (
            (lastTimeRewardApplicable() - citadel[_citadelId].timeOfLastClaim) *
                ((baseMiningRatePerHour * (getGridMultiple(_gridId) / 10)) / 3600) *
                (miningMultiple / 100)
        );
    }

    function combatOP(uint256 _citadelId) public view returns (uint256) {
        uint256 multiple = 0;
        for (uint256 i; i < citadel[_citadelId].pilot.length; ++i) {
            (,uint8 level) = pilotCollection.getOnchainPILOT(citadel[_citadelId].pilot[i]);
            multiple += pilotMultiple * (level * levelMultiple);
        }

        return multiple;
    }

    function combatDP(uint256 _citadelId) public view returns (uint256, uint256) {
        uint256 swarmMultiple = 0;
        uint256 siegeMultiple = 0;
        uint256 multiple = 0;
        for (uint256 i; i < citadel[_citadelId].pilot.length; ++i) {
            (,uint8 level) = pilotCollection.getOnchainPILOT(citadel[_citadelId].pilot[i]);
            multiple += pilotMultiple * (level * levelMultiple);
        }

        multiple += calculateBaseCitadelMultiple(weaponsProp[_citadelId]);
        multiple += calculateBaseCitadelMultiple(shieldProp[_citadelId]);
        
        (swarmMultiple, siegeMultiple) = calculateUniqueBonus(weaponsProp[_citadelId], engineProp[_citadelId], shieldProp[_citadelId]);
        swarmMultiple += multiple;
        siegeMultiple += multiple;

        return (swarmMultiple, siegeMultiple);
    }


    function getGridMultiple(uint256 _gridId) public view returns (uint256) {
        uint8 multiple = 0;
        if(_gridId >= 400 && _gridId <= 600) {
            multiple = 1;
            if(_gridId >= 450 && _gridId <= 550) {
                multiple = 2; 
            }
            if(_gridId >= 475 && _gridId <= 525) {
                multiple = 25;
            }
        }
        
        return multiple;
    }

    function calculateGridDistance(uint256 _fromGridId, uint256 _toGridId) public view returns (uint256) {
        uint256 higher;
        uint256 lower;
        if(_fromGridId >= _toGridId) {
            higher = _fromGridId;
            lower = _toGridId;
        } else {
            higher = _toGridId;
            lower = _fromGridId;
        }

        return (
            (higher % 4) + (higher / lower)
        );
    }

    function getCitadelFleedCount(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        // refactor for training
        return (fleet[_citadelId].sifGattaca, fleet[_citadelId].mhrudvogThrot, fleet[_citadelId].drebentraakht);
    }
}