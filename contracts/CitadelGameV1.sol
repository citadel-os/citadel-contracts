// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ICOMBATENGINE {
    function combatOP(
        uint256 _citadelId, 
        uint256[] memory _pilotIds, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external view returns (uint256);
    function combatDP(
        uint256 _citadelId, 
        uint256[] memory _pilotIds, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external view returns (uint256);
    function calculateMiningOutput(
        uint256 _citadelId, 
        uint256 _gridId, 
        uint256 claimTime
    ) external view returns (uint256);
    function calculateGridDistance(
        uint256 _fromGridId, 
        uint256 _toGridId
    ) external view returns (uint256);
    function calculateDestroyedFleet(
        uint256[] memory _offensivePilotIds,
        uint256[] memory _defensivePilotIds,
        uint256[7] memory _fleetTracker
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface IFLEETENGINE {
    function getTrainedFleet(uint256 _citadelId) external view returns (
        int256, int256, int256
    );
    function resolveTraining(uint256 _citadelId) external;
    function trainFleet(
        int256 _citadelId, 
        int256 _sifGattaca, 
        int256 _mhrudvogThrot, 
        int256 _drebentraakht
    ) external;
}

contract CitadelGameV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // imports
    IERC20 public immutable drakma;
    IERC721 public immutable citadelCollection;
    IERC721 public immutable pilotCollection;
    ICOMBATENGINE public immutable combatEngine;
    IFLEETENGINE public immutable fleetEngine;

    // events
    event DispatchRaid(
        uint256 fromCitadelId, 
        uint256 toCitadelId,
        uint256 timeRaidHit,
        uint256 offensiveCarryCapacity,
        uint256 drakmaRaided,
        uint256 offensiveSifGattacaDestroyed,
        uint256 offensiveMhrudvogThrotDestroyed,
        uint256 offensiveDrebentraakhtDestroyed,
        uint256 defensiveSifGattacaDestroyed,
        uint256 defensiveMhrudvogThrotDestroyed,
        uint256 defensiveDrebentraakhtDestroyed
    );

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
    }

    struct Fleet {
        int256 sifGattaca;
        int256 mhrudvogThrot;
        int256 drebentraakht;
    }

    struct Raid {
        uint256 toCitadel;
        Fleet fleet;
        uint256[] pilot;
        uint256 timeRaidHits;
    }

    // mappings
    mapping(uint256 => CitadelStaked) citadel; // index is _citadelId
    mapping(uint256 => Fleet) destroyedFleet; // index is _citadelId
    mapping(uint256 => Raid) raids; // index is _fromCitadelId
    mapping(uint256 => bool) grid; // index is _gridId

    //variables
    uint256 periodFinish = 1735700987; //JAN 1 2025, 2PM PT 
    uint256 maxGrid = 1023;
    uint8 maxFaction = 4;
    uint256 sifGattacaCary = 10000000000000000000;
    uint256 mhrudvogThrotCary = 2000000000000000000;
    uint256 drebentraakhtCary = 400000000000000000000;
    uint8 subgridDistortion = 1;
    uint256 gridTraversalTime = 30 minutes;
    uint256 minFleet = 10;
    uint256 raidMaxExpiry = 24 hours;
    uint256 claimInterval = 7 days;
    bool escapeHatchOn = false;
    

    constructor(
        IERC721 _citadelCollection, 
        IERC721 _pilotCollection, 
        IERC20 _drakma, 
        ICOMBATENGINE _combatEngine,
        IFLEETENGINE _fleetEngine
    ) {
        citadelCollection = _citadelCollection;
        pilotCollection = _pilotCollection;
        drakma = _drakma;
        combatEngine = _combatEngine;
        fleetEngine = _fleetEngine;
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
        citadel[_citadelId].timeOfLastClaim = 0;
        citadel[_citadelId].isLit = true;
        grid[_gridId] = true;

        // zero out trained fleet when citadel re-lit to grid
        (
            int256 trainedSifGattaca, 
            int256 trainedMhrudvogThrot, 
            int256 trainedDrebentraakht
        ) = fleetEngine.getTrainedFleet(_citadelId);
        destroyedFleet[_citadelId].sifGattaca = int256(trainedSifGattaca);
        destroyedFleet[_citadelId].mhrudvogThrot = int256(trainedMhrudvogThrot);
        destroyedFleet[_citadelId].drebentraakht = int256(trainedDrebentraakht);
    }

    function dimGrid(uint256 _citadelId) external nonReentrant {
        require(
            citadel[_citadelId].walletAddress == msg.sender,
            "must own lit citadel to withdraw"
        );
        
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
        require((citadel[_citadelId].timeOfLastClaim + claimInterval) < lastTimeRewardApplicable(), "one claim per interval permitted");
        uint256 drakmaToClaim = combatEngine.calculateMiningOutput(
            _citadelId, 
            citadel[_citadelId].gridId, 
            getMiningStartTime(_citadelId)
        ) + citadel[_citadelId].unclaimedDrakma;

        if(drakmaToClaim > 0) {
            drakma.safeTransfer(msg.sender, drakmaToClaim);
        }
        
        citadel[_citadelId].timeOfLastClaim = lastTimeRewardApplicable();
        citadel[_citadelId].unclaimedDrakma = 0;
    }

    function getMiningStartTime(uint256 _citadelId) internal view returns(uint256) {
        uint256 miningStartTime = citadel[_citadelId].timeOfLastClaim == 0 ? citadel[_citadelId].timeLit : citadel[_citadelId].timeOfLastClaim;
        miningStartTime = citadel[_citadelId].timeLastRaided > miningStartTime ? citadel[_citadelId].timeLastRaided : miningStartTime;
        return miningStartTime;
    }

    function sendRaid(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256[] calldata _pilot, 
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external nonReentrant {
        require(
            block.timestamp < periodFinish,
            "cannot raid passed the end of the season"
        );
        require(_fromCitadel != _toCitadel, "cannot raid own citadel");
        require(
            citadel[_fromCitadel].walletAddress == msg.sender,
            "must own lit citadel to raid"
        );
        require(
            citadel[_toCitadel].isLit == true,
            "defending citadel must be lit to raid"
        );

        fleetEngine.resolveTraining(_fromCitadel);
        (
            int256 totalSifGattaca, 
            int256 totalMhrudvogThrot, 
            int256 totalDrebentraakht
        ) = getCitadelFleetCount(_fromCitadel);

        require(
            _sifGattaca <= uint256(totalSifGattaca) &&
            _mhrudvogThrot <= uint256(totalMhrudvogThrot) &&
             _drebentraakht <= uint256(totalDrebentraakht),
            "cannot send more fleet than in citadel"
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
        
        if (gridDistance > subgridDistortion) {
            timeRaidHits += (gridDistance * gridTraversalTime);
        }

        require(
            timeRaidHits < periodFinish,
            "cannot raid passed the end of the season"
        );

        raids[_fromCitadel] = Raid(_toCitadel, Fleet(int256(_sifGattaca), int256(_mhrudvogThrot), int256(_drebentraakht)), _pilot, timeRaidHits);
        destroyedFleet[_fromCitadel].sifGattaca += int256(_sifGattaca);
        destroyedFleet[_fromCitadel].mhrudvogThrot += int256(_mhrudvogThrot);
        destroyedFleet[_fromCitadel].drebentraakht += int256(_drebentraakht);

        if (gridDistance <= subgridDistortion) {
            resolveRaidInternal(_fromCitadel);
        }
    }

    // public functions
    function resolveRaid(uint256 _fromCitadel) external nonReentrant {
        require(
            raids[_fromCitadel].timeRaidHits != 0,
            "citadel does not require raid resolution"
        );

        resolveRaidInternal(_fromCitadel);
    }


    /*
            defending fleet tracker trick
            [0] defendingSifGattaca
            [1] defendingMhrudvogThrot 
            [2] defendingDrebentraakht

            fleet tracker storage trick
            [0] offensiveSifGattacaDestroyed
            [1] offensiveMhrudvogThrotDestroyed
            [2] offensiveDrebentraakhtDestroyed
            [3] defensiveSifGattacaDestroyed
            [4] defensiveMhrudvogThrotDestroyed
            [5] defensiveDrebentraakhtDestroyed

            tempTracker storage trick
            [0] = raids[_fromCitadel].fleet.sifGattaca
            [1] = raids[_fromCitadel].fleet.mhrudvogThrot
            [2] = raids[_fromCitadel].fleet.drebentraakht
            [3] = toCitadel
            [4] = defendingSifGattaca
            [5] = defendingMhrudvogThrot
            [6] = defendingDrebentraakht
    */
    function resolveRaidInternal(uint256 _fromCitadel) internal {
        require(
            raids[_fromCitadel].timeRaidHits <= lastTimeRewardApplicable(),
            "cannot resolve a raid before it hits"
        );
        uint256 toCitadel = raids[_fromCitadel].toCitadel;
        fleetEngine.resolveTraining(toCitadel);
        // if left on grid 24 hours from hit time, fleet to defenders defect
        if(lastTimeRewardApplicable() > (raids[_fromCitadel].timeRaidHits + raidMaxExpiry)) {
            destroyedFleet[toCitadel].sifGattaca -= raids[_fromCitadel].fleet.sifGattaca;
            destroyedFleet[toCitadel].mhrudvogThrot -= raids[_fromCitadel].fleet.mhrudvogThrot;
            destroyedFleet[toCitadel].drebentraakht -= raids[_fromCitadel].fleet.drebentraakht;
            destroyedFleet[_fromCitadel].sifGattaca += raids[_fromCitadel].fleet.sifGattaca;
            destroyedFleet[_fromCitadel].mhrudvogThrot += raids[_fromCitadel].fleet.mhrudvogThrot;
            destroyedFleet[_fromCitadel].drebentraakht += raids[_fromCitadel].fleet.drebentraakht;
            delete raids[_fromCitadel];
            return;
        }
        
        int256[3] memory defendingFleetTracker;
        (
            defendingFleetTracker[0], 
            defendingFleetTracker[1], 
            defendingFleetTracker[2]
        ) = getCitadelFleetCount(toCitadel);

        uint256[7] memory tempTracker;
        tempTracker[0] = uint256(raids[_fromCitadel].fleet.sifGattaca);
        tempTracker[1] = uint256(raids[_fromCitadel].fleet.mhrudvogThrot);
        tempTracker[2] = uint256(raids[_fromCitadel].fleet.drebentraakht);
        tempTracker[3] = toCitadel;
        tempTracker[4] = uint256(defendingFleetTracker[0]);
        tempTracker[5] = uint256(defendingFleetTracker[1]);
        tempTracker[6] = uint256(defendingFleetTracker[2]);

        uint256[6] memory fleetTracker;
        (
            fleetTracker[0],
            fleetTracker[1],
            fleetTracker[2],
            fleetTracker[3],
            fleetTracker[4],
            fleetTracker[5]
        ) = combatEngine.calculateDestroyedFleet(
            raids[_fromCitadel].pilot, 
            citadel[toCitadel].pilot,
            tempTracker
        );

        // update fleet count of defender
        destroyedFleet[toCitadel].sifGattaca += int256(fleetTracker[3]);
        destroyedFleet[toCitadel].mhrudvogThrot += int256(fleetTracker[4]);
        destroyedFleet[toCitadel].drebentraakht += int256(fleetTracker[5]);

        // return fleet and empty raid
        destroyedFleet[_fromCitadel].sifGattaca -= 
            (raids[_fromCitadel].fleet.sifGattaca - int256(fleetTracker[0]));
        destroyedFleet[_fromCitadel].mhrudvogThrot -= 
            (raids[_fromCitadel].fleet.mhrudvogThrot - int256(fleetTracker[1]));
        destroyedFleet[_fromCitadel].drebentraakht -= 
            (raids[_fromCitadel].fleet.drebentraakht - int256(fleetTracker[2]));

        // transfer dk
        uint256 drakmaAvailable = combatEngine.calculateMiningOutput(
            toCitadel, 
            citadel[toCitadel].gridId, 
            getMiningStartTime(toCitadel)
        ) + citadel[toCitadel].unclaimedDrakma;

        uint256 drakmaCarry = (
            ((uint256(raids[_fromCitadel].fleet.sifGattaca) - fleetTracker[0]) * sifGattacaCary) +
            ((uint256(raids[_fromCitadel].fleet.mhrudvogThrot) - fleetTracker[1]) * mhrudvogThrotCary) +
            ((uint256(raids[_fromCitadel].fleet.drebentraakht) - fleetTracker[2]) * drebentraakhtCary)
        );

        uint256 dkToTransfer = drakmaAvailable > drakmaCarry ? drakmaCarry : drakmaAvailable;
        
        citadel[toCitadel].unclaimedDrakma += (drakmaAvailable - dkToTransfer);
        citadel[_fromCitadel].unclaimedDrakma += (dkToTransfer * 9) / 10;
        drakma.safeTransfer(msg.sender, (dkToTransfer / 10));
        citadel[toCitadel].timeLastRaided = lastTimeRewardApplicable();

        emit DispatchRaid(
            _fromCitadel,
            toCitadel,
            raids[_fromCitadel].timeRaidHits,
            drakmaCarry,
            dkToTransfer,
            fleetTracker[0],
            fleetTracker[1],
            fleetTracker[2],
            fleetTracker[3],
            fleetTracker[4],
            fleetTracker[5]
        );
        delete raids[_fromCitadel];
    }

    // only owner
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
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

    function getCitadelFleetCount(uint256 _citadelId) public view returns (int256, int256, int256) {
        (
            int256 trainedSifGattaca, 
            int256 trainedMhrudvogThrot, 
            int256 trainedDrebentraakht
        ) = fleetEngine.getTrainedFleet(_citadelId);
        
        if(
            trainedSifGattaca >= destroyedFleet[_citadelId].sifGattaca &&
            trainedMhrudvogThrot >= destroyedFleet[_citadelId].mhrudvogThrot &&
            trainedDrebentraakht >= destroyedFleet[_citadelId].drebentraakht
        ) {
            return (
                trainedSifGattaca - destroyedFleet[_citadelId].sifGattaca,
                trainedMhrudvogThrot - destroyedFleet[_citadelId].mhrudvogThrot,
                trainedDrebentraakht - destroyedFleet[_citadelId].drebentraakht
            );
        }
        return (0,0,0);
    }

    function getCitadel(uint256 _citadelId) public view returns (address, uint256, uint8, uint256, bool) {
        return (
                citadel[_citadelId].walletAddress,
                citadel[_citadelId].gridId,
                citadel[_citadelId].factionId,
                citadel[_citadelId].pilot.length,
                citadel[_citadelId].isLit
        );
    }

    function getCitadelPilot(uint256 _citadelId) public view returns( uint256[] memory){
        return citadel[_citadelId].pilot;
    }

    function getCitadelMining(uint256 _citadelId) public view returns (uint256, uint256, uint256, uint256) {
        return (
                citadel[_citadelId].timeLit,
                citadel[_citadelId].timeOfLastClaim,
                citadel[_citadelId].timeLastRaided,
                citadel[_citadelId].unclaimedDrakma
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
                uint256(raids[_fromCitadelId].fleet.sifGattaca),
                uint256(raids[_fromCitadelId].fleet.mhrudvogThrot),
                uint256(raids[_fromCitadelId].fleet.drebentraakht),
                raids[_fromCitadelId].pilot.length,
                raids[_fromCitadelId].timeRaidHits
        );
    }
}
