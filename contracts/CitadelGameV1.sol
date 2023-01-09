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
        uint256 timeLit;
        uint256 timeLastRaided;
        uint256 unclaimedDrakma;
        uint256[] pilot;
        bool isLit;
        bool isOnline;
        uint256 fleetPoints;
    }

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
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
        uint256 timeRaidHits;
    }

    // mappings
    mapping(uint256 => CitadelStaked) public citadel; // index is _citadelId
    mapping(uint256 => AllFleet) public fleet; // index is _citadelId
    mapping(uint256 => Raid) public raids; // index is _fromCitadelId
    mapping(uint256 => bool) public grid; // index is _gridId

    //variables
    uint256 periodFinish = 1674943200; //JAN 28 2023, 2PM PT 
    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;
    uint256 public sifGattacaPrice = 20000000000000000000;
    uint256 public mhrudvogThrotPrice = 40000000000000000000;
    uint256 public drebentraakhtPrice = 800000000000000000000;
    uint256 public sifGattacaTrainingTime = 5 minutes;
    uint256 public mhrudvogThrotTrainingTime = 15 minutes;
    uint256 public drebentraakhtTrainingTime = 1 hours;
    uint256 public sifGattacaCary = 10000000000000000000;
    uint256 public mhrudvogThrotCary = 2000000000000000000;
    uint256 public drebentraakhtCary = 400000000000000000000;
    uint8 subgridDistortion = 1;
    uint256 gridTraversalTime = 30 minutes;
    uint256 minFleet = 10;
    uint256 raidMaxExpiry = 24 hours;
    uint256 claimInterval = 7 days;
    bool escapeHatchOn = false;
    

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
        citadel[_citadelId].timeLit = blockTimeNow;
        citadel[_citadelId].timeLastRaided = blockTimeNow;
        citadel[_citadelId].isLit = true;
        citadel[_citadelId].isOnline = true;
        citadel[_citadelId].fleetPoints = 0;
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].isValue = true;
            fleet[_citadelId].fleet = Fleet(10,2,0);
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
        citadel[_citadelId].timeLit = 0;
        citadel[_citadelId].timeLastRaided = 0;
        citadel[_citadelId].isLit = false;
        citadel[_citadelId].isOnline = false;
        delete citadel[_citadelId].pilot;
    }

    function escapeHatch(uint256 _citadelId) external nonReentrant {
        require(escapeHatchOn == true, "escapeHatch is closed");
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own lit citadel to withdraw"
        );

        for (uint256 i; i < citadel[_citadelId].pilot.length; ++i) {
            pilotCollection.transferFrom(address(this), msg.sender, citadel[_citadelId].pilot[i]);
        }
        citadelCollection.transferFrom(address(this), msg.sender, _citadelId);
    }

    function claim(uint256 _citadelId) external nonReentrant {
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own citadel to claim"
        );
        claimInternal(_citadelId);
    }

    function claimInternal(uint256 _citadelId) internal {
        require(citadel[_citadelId].isLit == true, "cannot claim unlit citadel");
        require(citadel[_citadelId].isOnline == true, "cannot claim offline citadel");
        require((citadel[_citadelId].timeOfLastClaim + claimInterval) < lastTimeRewardApplicable(), "one claim per interval permitted");
        uint256 drakmaToClaim = combatEngine.calculateMiningOutput(_citadelId, citadel[_citadelId].gridId, getMiningStartTime(_citadelId))
            + citadel[_citadelId].unclaimedDrakma;

        if(drakmaToClaim > 0) {
            drakma.safeTransfer(msg.sender, drakmaToClaim);
        }
        
        citadel[_citadelId].timeOfLastClaim = lastTimeRewardApplicable();
        citadel[_citadelId].unclaimedDrakma = 0;
    }

    function getMiningStartTime(uint256 _citadelId) internal returns(uint256) {
        uint256 miningStartTime = citadel[_citadelId].timeOfLastClaim == 0 ? citadel[_citadelId].timeLit : citadel[_citadelId].timeOfLastClaim;
        miningStartTime = citadel[_citadelId].timeLastRaided > miningStartTime ? citadel[_citadelId].timeLastRaided : miningStartTime;
        return miningStartTime;
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

        uint256 timeTrainingDone = 0;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        if(_mhrudvogThrot * mhrudvogThrotTrainingTime > timeTrainingDone) {
            timeTrainingDone = _mhrudvogThrot * mhrudvogThrotTrainingTime;
        }
        if(_drebentraakht * drebentraakhtTrainingTime > timeTrainingDone) {
            timeTrainingDone = _drebentraakht * drebentraakhtTrainingTime;
        }
        require(
            block.timestamp + timeTrainingDone < periodFinish,
            "cannot train fleet passed the end of the season"
        );

        fleetCost += _sifGattaca * sifGattacaPrice;
        fleetCost += _mhrudvogThrot * mhrudvogThrotPrice;
        fleetCost += _drebentraakht * drebentraakhtPrice;
        require(drakma.transferFrom(msg.sender, address(this), fleetCost));

        fleet[_citadelId].trainingDone = lastTimeRewardApplicable() + timeTrainingDone;
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;
    }

    function sendRaid(uint256 _fromCitadel, uint256 _toCitadel, uint256[] calldata _pilot, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) external nonReentrant {
        require(_fromCitadel != _toCitadel, "cannot raid own citadel");
        require(
            citadel[_fromCitadel].walletAddress == msg.sender,
            "must own lit citadel to raid"
        );
        require(
            citadel[_fromCitadel].isOnline == true,
            "attcking citadel must be lit and online to raid"
        );
        require(
            citadel[_toCitadel].isOnline == true,
            "defending citadel must be lit and online to raid"
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
        timeRaidHits += (gridDistance * gridTraversalTime);
        
        if (gridDistance <= subgridDistortion) {
            require(
                timeRaidHits < periodFinish,
                "cannot raid passed the end of the season"
            );
        } else {
            require(
                block.timestamp < periodFinish,
                "cannot raid passed the end of the season"
            );
        }


        raids[_fromCitadel] = Raid(_toCitadel, Fleet(_sifGattaca, _mhrudvogThrot, _drebentraakht), _pilot, timeRaidHits);
        fleet[_fromCitadel].fleet.sifGattaca -= _sifGattaca;
        fleet[_fromCitadel].fleet.mhrudvogThrot -= _mhrudvogThrot;
        fleet[_fromCitadel].fleet.drebentraakht -= _drebentraakht;
        citadel[_fromCitadel].isOnline = false;
        citadel[_toCitadel].isOnline = false;

        if (gridDistance <= subgridDistortion) {
            resolveRaidInternal(_fromCitadel);
        }
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
        fleet[toCitadel].fleet.sifGattaca = fleet[toCitadel].fleet.sifGattaca - (fleet[toCitadel].fleet.sifGattaca * combatDP * 25) / ((combatOP + combatDP) * 100);
        fleet[toCitadel].fleet.mhrudvogThrot = fleet[toCitadel].fleet.mhrudvogThrot - (fleet[toCitadel].fleet.mhrudvogThrot * combatDP * 25) / ((combatOP + combatDP) * 100);
        fleet[toCitadel].fleet.drebentraakht = fleet[toCitadel].fleet.drebentraakht - (fleet[toCitadel].fleet.drebentraakht * combatDP * 25) / ((combatOP + combatDP) * 100);

        raids[_fromCitadel].fleet.sifGattaca = raids[_fromCitadel].fleet.sifGattaca - (raids[_fromCitadel].fleet.sifGattaca * combatOP * 25) / ((combatOP + combatDP) * 100);
        raids[_fromCitadel].fleet.mhrudvogThrot = raids[_fromCitadel].fleet.mhrudvogThrot - (raids[_fromCitadel].fleet.mhrudvogThrot * combatOP * 25) / ((combatOP + combatDP) * 100);
        raids[_fromCitadel].fleet.drebentraakht = raids[_fromCitadel].fleet.drebentraakht - (raids[_fromCitadel].fleet.drebentraakht * combatOP * 25) / ((combatOP + combatDP) * 100);

        // transfer dk
        uint256 drakmaAvailable = combatEngine.calculateMiningOutput(toCitadel, citadel[toCitadel].gridId, getMiningStartTime(toCitadel)) + citadel[toCitadel].unclaimedDrakma;
        uint256 drakmaCarry = (
            (raids[_fromCitadel].fleet.sifGattaca * sifGattacaCary) +
            (raids[_fromCitadel].fleet.mhrudvogThrot * mhrudvogThrotCary) +
            (raids[_fromCitadel].fleet.drebentraakht * drebentraakhtCary)
        );
        uint256 dkToTransfer = drakmaAvailable > drakmaCarry ? drakmaCarry : drakmaAvailable;
        citadel[toCitadel].unclaimedDrakma += (drakmaAvailable - dkToTransfer);
        citadel[_fromCitadel].unclaimedDrakma += (dkToTransfer * 9) / 10;
        drakma.safeTransfer(msg.sender, (dkToTransfer / 10));
        citadel[toCitadel].timeLastRaided = lastTimeRewardApplicable();
        citadel[toCitadel].isOnline = true;
        citadel[_fromCitadel].isOnline = true;
        
        // return fleet and empty raid
        fleet[_fromCitadel].fleet.sifGattaca += raids[_fromCitadel].fleet.sifGattaca;
        fleet[_fromCitadel].fleet.mhrudvogThrot += raids[_fromCitadel].fleet.mhrudvogThrot;
        fleet[_fromCitadel].fleet.drebentraakht += raids[_fromCitadel].fleet.drebentraakht;
        delete raids[_fromCitadel];

    }

    function resolveTraining(uint256 _citadelId) internal {
        if(fleet[_citadelId].trainingDone <= lastTimeRewardApplicable()) {
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

    function updateFleetParams(
        uint256 _sifGattacaPrice, 
        uint256 _mhrudvogThrotPrice, 
        uint256 _drebentraakhtPrice, 
        uint256 _sifGattacaTrainingTime,
        uint256 _mhrudvogThrotTrainingTime,
        uint256 _drebentraakhtTrainingTime
    ) external onlyOwner {
        sifGattacaPrice = _sifGattacaPrice;
        mhrudvogThrotPrice = _mhrudvogThrotPrice;
        drebentraakhtPrice = _drebentraakhtPrice;
        sifGattacaTrainingTime = _sifGattacaTrainingTime;
        mhrudvogThrotTrainingTime = _mhrudvogThrotTrainingTime;
        drebentraakhtTrainingTime = _drebentraakhtTrainingTime;
    }

    function updateGameParams(
        uint256 _periodFinish, 
        uint8 _subgridDistortion, 
        uint256 _gridTraversalTime, 
        bool _escapeHatchOn
    ) external onlyOwner {
        periodFinish = _periodFinish;
        subgridDistortion = _subgridDistortion;
        escapeHatchOn = _escapeHatchOn;
        gridTraversalTime = _gridTraversalTime;
    }

    // public views
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getCitadelFleetCount(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        uint256 sifGattaca = fleet[_citadelId].fleet.sifGattaca;
        uint256 mhrudvogThrot = fleet[_citadelId].fleet.mhrudvogThrot;
        uint256 drebentraakht = fleet[_citadelId].fleet.drebentraakht;
        if(fleet[_citadelId].trainingDone <= lastTimeRewardApplicable()) {
            sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
        }
        return (sifGattaca, mhrudvogThrot, drebentraakht);
    }

    function getCitadelFleetCountTraining(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        uint256 sifGattaca = 0;
        uint256 mhrudvogThrot = 0;
        uint256 drebentraakht = 0;
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

    function getCitadelMining(uint256 _citadelId) public view returns (uint256, uint256, uint256, uint256, bool) {
        return (
                citadel[_citadelId].timeLit,
                citadel[_citadelId].timeOfLastClaim,
                citadel[_citadelId].timeLastRaided,
                citadel[_citadelId].unclaimedDrakma,
                citadel[_citadelId].isOnline
        );
    }

    function getGrid(uint256 _gridId) public view returns (bool) {
        return (
                grid[_gridId]
        );
    }

    function getRaid(uint256 _fromCitadelId) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
                raids[_fromCitadelId].toCitadel,
                raids[_fromCitadelId].fleet.sifGattaca,
                raids[_fromCitadelId].fleet.mhrudvogThrot,
                raids[_fromCitadelId].fleet.drebentraakht,
                raids[_fromCitadelId].pilot.length,
                raids[_fromCitadelId].timeRaidHits
        );
    }
}
