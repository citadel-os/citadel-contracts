// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

interface ICOMBATENGINE {
    function combatOP(uint256 _citadelId, uint256[] memory _pilotIds, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external view returns (uint256);
    function combatDP(uint256 _citadelId, uint256[] memory _pilotIds, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external view returns (uint256);
    function calculateMiningOutput(uint256 _citadelId, uint256 _gridId, uint256 claimTime) external view returns (uint256);
    function calculateGridDistance(uint256 _fromGridId, uint256 _toGridId) external view returns (uint256);
}

contract CitadelGameV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ICOMBATENGINE public immutable combatEngine;

    // data structures
    struct CitadelStaked {
        address walletAddress;
        uint256 gridId;
        uint8 factionId;
        uint256 timeOfLastClaim;
        uint256 timeOfLastRaid;
        uint256 timeOfLastRaidClaim;
        uint256 unclaimedDrakma;
        uint256[] pilot;
        bool isLit;
        bool isOnline;
        uint256 timeWentOffline;
        uint256 fleetPoints;
    }

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
        bool isValue;
    }

    struct AllFleet {
        Fleet fleet;
        Fleet trainingFleet;
        bool isValue;
        uint256 trainingDone;
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
    mapping(uint256 => AllFleet) public fleet; // index is _citadelId
    mapping(uint256 => Raid) public raids; // index is _fromCitadelId
    mapping(uint256 => bool) public grid; // index is _gridId

    //variables
    uint256 periodFinish = 1674943200; //JAN 28 2023, 2PM PT 
    uint256 maxGrid = 1024;
    uint8 maxFaction = 5;
    uint256 public sifGattacaPrice = 20000000000000000000;
    uint256 public mhrudvogThrotPrice = 40000000000000000000;
    uint256 public drebentraakhtPrice = 800000000000000000000;
    uint256 public sifGattacaTrainingTime = 2 hours;
    uint256 public mhrudvogThrotTrainingTime = 5 hours;
    uint256 public drebentraakhtTrainingTime = 24 hours;
    uint256 public sifGattacaCary = 10;
    uint256 public mhrudvogThrotCary = 2;
    uint256 public drebentraakhtCary = 400;
    bool public subgridOpen = false;
    uint256 minFleet = 500;
    uint256 raidMaxExpiry = 24 hours;
    

    constructor(IERC721 _citadelCollection, IERC721 _pilotCollection, IERC20 _drakma, ICOMBATENGINE _combatEngine) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        combatEngine = _combatEngine;
    }

    // external functions
    function liteGrid(uint256 _citadelId, uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) external nonReentrant {
        require(
            citadelCollection.ownerOf(_citadelId) == msg.sender,
            "must own citadel to stake"
        );
        require(grid[_gridId] == false, "grid already lit");
        require(_gridId <= maxGrid && _gridId != 0, "invalid grid");
        require(_factionId <= maxFaction, "invalid faction");
        for (uint256 i; i < _pilotIds.length; ++i) {
            require(
                pilotCollection.ownerOf(_pilotIds[i]) == msg.sender,
                "must own pilot to stake"
            );
        }

        citadelCollection.transferFrom(msg.sender, address(this), _citadelId);
        for (uint256 i; i < _pilotIds.length; ++i) {
            pilotCollection.transferFrom(msg.sender, address(this), _pilotIds[i]);
            citadel[_citadelId].pilot.push(_pilotIds[i]);
        }

        uint256 blockTimeNow = lastTimeRewardApplicable();
        citadel[_citadelId].walletAddress = msg.sender;
        citadel[_citadelId].gridId = _gridId;
        citadel[_citadelId].factionId = _factionId;
        citadel[_citadelId].timeOfLastClaim = blockTimeNow;
        citadel[_citadelId].timeOfLastRaid = blockTimeNow;
        citadel[_citadelId].timeOfLastRaidClaim = blockTimeNow;
        citadel[_citadelId].isLit = true;
        citadel[_citadelId].isOnline = true;
        citadel[_citadelId].fleetPoints = 0;
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].isValue = true;
            fleet[_citadelId].fleet = Fleet(0,0,0,true);
        }
        grid[_gridId] = true;
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

        grid[citadel[_citadelId].gridId] = false;
        citadel[_citadelId].walletAddress = 0x0000000000000000000000000000000000000000;
        citadel[_citadelId].gridId = 0;
        citadel[_citadelId].factionId = 0;
        citadel[_citadelId].timeOfLastClaim = 0;
        citadel[_citadelId].timeOfLastRaid = 0;
        citadel[_citadelId].timeOfLastRaidClaim = 0;
        citadel[_citadelId].isLit = false;
        citadel[_citadelId].isOnline = false;
        citadel[_citadelId].timeWentOffline = 0;
        delete citadel[_citadelId].pilot;
    }

    function claim(uint256 _citadelId) external nonReentrant {
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own citadel to claim"
        );
        claimInternal(_citadelId);
    }

    function claimInternal(uint256 _citadelId) internal {
        require(citadel[_citadelId].timeOfLastClaim > 0, "cannot claim unlit citadel");
        uint256 claimTime = citadel[_citadelId].timeOfLastRaidClaim > citadel[_citadelId].timeOfLastClaim ? citadel[_citadelId].timeOfLastRaidClaim : citadel[_citadelId].timeOfLastClaim; 
        uint256 minedDrakma = combatEngine.calculateMiningOutput(_citadelId, citadel[_citadelId].gridId, claimTime);
        require(minedDrakma > 0, "you have no drakma mined");
        drakma.safeTransfer(msg.sender, minedDrakma);
        citadel[_citadelId].timeOfLastClaim = lastTimeRewardApplicable();
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own lit citadel to raid"
        );
        require(
            citadel[_citadelId].isLit == true && citadel[_citadelId].isOnline == true,
            "citadel must be lit and online to train fleet"
        );
        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train new fleet until previous has finished"
        );
        uint256 fleetCost = 0;
        fleetCost += _sifGattaca * sifGattacaPrice;
        fleetCost += _mhrudvogThrot * mhrudvogThrotPrice;
        fleetCost += _drebentraakht * drebentraakhtPrice;
        require(drakma.transferFrom(msg.sender, address(this), fleetCost));

        uint256 timeTrainingDone = 0;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        if(_mhrudvogThrot * mhrudvogThrotTrainingTime > timeTrainingDone) {
            timeTrainingDone = _mhrudvogThrot * mhrudvogThrotTrainingTime;
        }
        if(_drebentraakht * drebentraakhtTrainingTime > timeTrainingDone) {
            timeTrainingDone = _drebentraakht * drebentraakhtTrainingTime;
        }
        fleet[_citadelId].trainingDone = lastTimeRewardApplicable() + timeTrainingDone;
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;
    }

    function sendRaid(uint256 _fromCitadel, uint256 _toCitadel, uint256[] calldata _pilot, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant returns (uint256) {
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

        // move fully trained citadel out of training queue
        resolveTraining(_fromCitadel);
        require(
            _sifGattaca <= fleet[_fromCitadel].fleet.sifGattaca &&
            _mhrudvogThrot <= fleet[_fromCitadel].fleet.mhrudvogThrot &&
             _drebentraakht <= fleet[_fromCitadel].fleet.drebentraakht,
            "cannot send more fleet than are trained"
        );
        require(
            _sifGattaca + _mhrudvogThrot + _drebentraakht >= minFleet,
            "fleet sent in raid must exceed minimum for raiding"
        );

        for (uint256 i; i < _pilot.length; ++i) {
            bool pilotFound = false;
            for (uint256 j; j < citadel[_fromCitadel].pilot.length; ++j) {
                if(_pilot[i] == citadel[_fromCitadel].pilot[j]) {
                    pilotFound = true;
                    break;
                }
            }
            require(pilotFound == true, "pilot sent must be staked to raiding citadel");
        }

        // raids immediate when subgrid open
        uint256 timeRaidHits = lastTimeRewardApplicable();
        uint256 gridDistance = combatEngine.calculateGridDistance(citadel[_fromCitadel].gridId, citadel[_toCitadel].gridId);
        timeRaidHits += (gridDistance * 3600000);

        raids[_fromCitadel] = Raid(_toCitadel, Fleet(_sifGattaca, _mhrudvogThrot, _drebentraakht, true), _pilot, true, timeRaidHits);
        fleet[_fromCitadel].fleet.sifGattaca -= _sifGattaca;
        fleet[_fromCitadel].fleet.mhrudvogThrot -= _mhrudvogThrot;
        fleet[_fromCitadel].fleet.drebentraakht -= _drebentraakht;
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
        uint256 toCitadel = raids[_fromCitadel].toCitadel;
        require(
            citadel[_fromCitadel].isOnline == false || citadel[toCitadel].isOnline == false,
            "citadel does not require raid resolution"
        );

        resolveRaidInternal(_fromCitadel);
    }

    // internal functions
    function resolveRaidInternal(uint256 _fromCitadel) internal {
        uint256 toCitadel = raids[_fromCitadel].toCitadel;
        resolveTraining(toCitadel);

        // if left on grid 24 hours from hit time, fleet to defenders defect
        if(lastTimeRewardApplicable() > (raids[_fromCitadel].timeRaidHits + raidMaxExpiry)) {
            fleet[toCitadel].fleet.sifGattaca += raids[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].fleet.mhrudvogThrot += raids[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].fleet.drebentraakht += raids[_fromCitadel].fleet.drebentraakht;
            delete raids[_fromCitadel];
            return;
        }

        uint256 combatOP = combatEngine.combatOP(_fromCitadel, raids[_fromCitadel].pilot, raids[_fromCitadel].fleet.sifGattaca, raids[_fromCitadel].fleet.mhrudvogThrot, raids[_fromCitadel].fleet.drebentraakht);
        uint256 combatDP = combatEngine.combatDP(toCitadel, citadel[toCitadel].pilot, fleet[toCitadel].fleet.sifGattaca, fleet[toCitadel].fleet.mhrudvogThrot, fleet[toCitadel].fleet.drebentraakht);

        // calculate fleet damage
        fleet[toCitadel].fleet.sifGattaca = fleet[toCitadel].fleet.sifGattaca * (combatDP / (combatOP + combatDP));
        fleet[toCitadel].fleet.mhrudvogThrot = fleet[toCitadel].fleet.mhrudvogThrot * (combatDP / (combatOP + combatDP));
        fleet[toCitadel].fleet.drebentraakht = fleet[toCitadel].fleet.drebentraakht * (combatDP / (combatOP + combatDP));

        raids[_fromCitadel].fleet.sifGattaca = raids[_fromCitadel].fleet.sifGattaca * (combatOP / (combatOP + combatDP));
        raids[_fromCitadel].fleet.sifGattaca = raids[_fromCitadel].fleet.sifGattaca * (combatOP / (combatOP + combatDP));
        raids[_fromCitadel].fleet.sifGattaca = raids[_fromCitadel].fleet.sifGattaca * (combatOP / (combatOP + combatDP));

        // transfer dk
        uint256 claimTime = citadel[_fromCitadel].timeOfLastRaidClaim > citadel[_fromCitadel].timeOfLastClaim ? citadel[_fromCitadel].timeOfLastRaidClaim : citadel[_fromCitadel].timeOfLastClaim; 
        uint256 drakmaAvailable = combatEngine.calculateMiningOutput(toCitadel, citadel[toCitadel].gridId, claimTime) +
            citadel[toCitadel].unclaimedDrakma;
        uint256 drakmaCarry = (
            (raids[_fromCitadel].fleet.sifGattaca * sifGattacaCary) +
            (raids[_fromCitadel].fleet.mhrudvogThrot * mhrudvogThrotCary) +
            (raids[_fromCitadel].fleet.drebentraakht * drebentraakhtCary)
        );
        uint256 dkToTransfer = drakmaAvailable > drakmaCarry ? drakmaCarry : drakmaAvailable;
        drakma.safeTransfer(msg.sender, (dkToTransfer / 10));
        drakma.safeTransfer(citadel[_fromCitadel].walletAddress, ((dkToTransfer * 9) / 10));
        citadel[_fromCitadel].timeOfLastRaidClaim = lastTimeRewardApplicable();
        
        // return fleet and empty raid
        fleet[_fromCitadel].fleet.sifGattaca += raids[_fromCitadel].fleet.sifGattaca;
        fleet[_fromCitadel].fleet.mhrudvogThrot += raids[_fromCitadel].fleet.mhrudvogThrot;
        fleet[_fromCitadel].fleet.drebentraakht += raids[_fromCitadel].fleet.drebentraakht;
        delete raids[_fromCitadel];

    }

    function resolveTraining(uint256 _citadelId) internal {
        if(fleet[_citadelId].trainingDone >= lastTimeRewardApplicable()) {
            fleet[_citadelId].trainingDone = 0;
            fleet[_citadelId].fleet.sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            fleet[_citadelId].trainingFleet.sifGattaca = 0;
            fleet[_citadelId].fleet.mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            fleet[_citadelId].fleet.drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
            fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    // only owner
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }

    // internal views
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // public views
    function getCitadelFleetCount(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        uint256 sifGattaca = fleet[_citadelId].fleet.sifGattaca;
        uint256 mhrudvogThrot = fleet[_citadelId].fleet.mhrudvogThrot;
        uint256 drebentraakht = fleet[_citadelId].fleet.drebentraakht;
        if(fleet[_citadelId].trainingDone >= lastTimeRewardApplicable()) {
            sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
        }
        
        return (sifGattaca, mhrudvogThrot, drebentraakht);
    }

    function getCitadel(uint256 _citadelId) public view returns (address, uint256, uint8, uint256, bool, uint256) {
        return (
                citadel[_citadelId].walletAddress,
                citadel[_citadelId].gridId,
                citadel[_citadelId].factionId,
                citadel[_citadelId].pilot.length,
                citadel[_citadelId].isLit,
                citadel[_citadelId].fleetPoints
        );
    }

    function getCitadelMining(uint256 _citadelId) public view returns (uint256, uint256, uint256, uint256, bool, uint256) {
        return (
                citadel[_citadelId].timeOfLastClaim,
                citadel[_citadelId].timeOfLastRaid,
                citadel[_citadelId].timeOfLastRaidClaim,
                citadel[_citadelId].unclaimedDrakma,
                citadel[_citadelId].isOnline,
                citadel[_citadelId].timeWentOffline
        );
    }

    function getGrid(uint256 _gridId) public view returns (bool) {
        return (
                grid[_gridId]
        );
    }
}
