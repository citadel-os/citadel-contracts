// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

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
        uint256 lastClaimTime
    ) external view returns (uint256);
    function calculateGridDistance(
        uint256 _a, 
        uint256 _b
    ) external view returns (uint256);
    function calculateDestroyedFleet(
        uint256 _offensivePilotId,
        uint256[3] memory _defensivePilotIds,
        uint256[6] memory _fleetTracker,
        uint256 _defensiveCitadelId
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function subgridDistortion() external view returns (uint256);
    function gridTraversalTime() external view returns (uint256);
    function calculateGridTraversal(
        uint256 _gridA, 
        uint256 _gridB
    ) external view returns (uint256, uint256);
    function calculateTrainingTime(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) external view returns (uint256);
    function calculateTrainedFleet(
        uint256[3] calldata _fleet,
        uint256 _timeTrainingStarted,
        uint256 _timeTrainingDone
    ) external view returns (uint256, uint256, uint256);
    function isTreasuryMaxed(uint256 treasuryBal) external view returns (bool);
}


contract StorageV2 is Ownable {

    // imports
    ICOMBATENGINE public immutable combatEngine;

    // data structures
    struct CitadelGrid {
        uint256 gridId;
        uint8 capitalId;
        uint256 timeOfLastClaim;
        uint256 timeLit;
        uint256 timeLastSieged;
        uint256 unclaimedDrakma;
        uint256[3] pilot;
        uint8 marker;
    }

    struct Fleet {
        uint256 sifGattaca;
        uint256 mhrudvogThrot;
        uint256 drebentraakht;
    }

    struct FleetReinforce {
        Fleet fleet;
        uint256 toCitadel;
        uint256 fleetArrivalTime;
    }

    struct FleetAcademy {
        Fleet stationedFleet;
        Fleet trainingFleet;
        uint256 trainingStarted;
        uint256 trainingDone;
        bool isValue;
    }

    struct Siege {
        uint256 toCitadel;
        Fleet fleet;
        uint256 pilot;
        uint256 timeSiegeHits;
    }

    struct Grid {
        bool isCapital;
        uint256 sovereignUntil;
        bool isLit;
        uint256 citadelId;
    }

    struct Capital {
        uint256 gridId;
        uint256 treasury;
        uint256 bribeAmt;
        string name;
        uint256 lastSack;
    }

    // mappings
    mapping(uint256 => CitadelGrid) public citadel; // index is _citadelId
    mapping(uint256 => FleetAcademy) public fleet; // index is _citadelId
    mapping(uint256 => Siege) siege; // index is _fromCitadelId
    mapping(uint256 => FleetReinforce) reinforcements; // index is _fromCitadelId
    mapping(uint256 => bool) pilot; // index is _pilotId, value isLit
    mapping(uint256 => Grid) public grid;
    mapping(uint8 => Capital) capital;

    //variables
    uint256 gameStart;
    uint256 sifGattacaCary = 10000000000000000000;
    uint256 mhrudvogThrotCary = 2000000000000000000;
    uint256 drebentraakhtCary = 400000000000000000000;
    uint256 siegeMaxExpiry = 24 hours;
    uint256 claimInterval = 64 days;
    address accessAddress;

    event DispatchSiege(
        uint256 fromCitadelId, 
        uint256 toCitadelId,
        uint256 timeSiegeHit,
        uint256 offensiveCarryCapacity,
        uint256 drakmaSieged,
        uint256 offensiveSifGattacaDestroyed,
        uint256 offensiveMhrudvogThrotDestroyed,
        uint256 offensiveDrebentraakhtDestroyed,
        uint256 defensiveSifGattacaDestroyed,
        uint256 defensiveMhrudvogThrotDestroyed,
        uint256 defensiveDrebentraakhtDestroyed
    );

    constructor(
        ICOMBATENGINE _combatEngine
    ) {
        combatEngine = _combatEngine;
        gameStart = block.timestamp;

        capital[0] = Capital(495, 0, 100000000000000000000000, "ANNEXATION", 0); //ANNEXATION CAPITAL TREASURY
        capital[1] = Capital(615, 0, 100000000000000000000000, "AUTONOMOUS ZONE", 0); //AUTONOMOUS ZONE CAPITAL TREASURY
        capital[2] = Capital(661, 0, 100000000000000000000000, "SANCTION", 0); //SANCTION CAPITAL TREASURY
        capital[3] = Capital(303, 0, 100000000000000000000000, "NETWORK STATE", 0); //NETWORK STATE CAPITAL TREASURY
    }

    // public functions
    function liteGrid(
        uint256 _citadelId, 
        uint256[3] calldata _pilotIds, 
        uint256 _gridId, 
        uint8 _capitalId,
        uint256 _sovereignUntil
    ) public {
        checkAccess();
        require(!grid[_gridId].isLit, "cannot lite");
        require(citadel[_citadelId].timeLit == 0, "cannot lite");

        for (uint256 i; i < _pilotIds.length; ++i) {
            if (_pilotIds[i] != 0) {
                require(!pilot[_pilotIds[i]], "cannot lite");
                pilot[_pilotIds[i]] = true;
            }
        }

        citadel[_citadelId] = CitadelGrid(
            _gridId,
            _capitalId,
            0,
            block.timestamp,
            0,
            0,
            _pilotIds,
            0
        );

        grid[_gridId] = Grid(false, _sovereignUntil, true, _citadelId);
    }

    function usurpCitadel(uint256 _fromCitadel, uint256 _toCitadel) internal {
        uint256 fromGrid = citadel[_fromCitadel].gridId;
        uint256 toGrid = citadel[_toCitadel].gridId;
        citadel[_fromCitadel].gridId = toGrid;
        citadel[_toCitadel].gridId = fromGrid;
        swapGrid(fromGrid, toGrid);
    }

    function swapGridSafe(uint256 _fromGrid, uint256 _toGrid) internal {
        require(!grid[_toGrid].isLit, "cannot usurp lit grid");
        swapGrid(_fromGrid, _toGrid);
    }

    function swapGrid(uint256 _fromGrid, uint256 _toGrid) internal {
        uint256 fromCitadelId;
        uint256 toCitadelId;
        (fromCitadelId,,,) = getGrid(_fromGrid);
        (toCitadelId,,,) = getGrid(_toGrid);
        grid[_fromGrid].citadelId = toCitadelId;
        grid[_toGrid].citadelId = fromCitadelId;
        citadel[fromCitadelId].gridId = _toGrid;
        citadel[toCitadelId].gridId = _fromGrid;
    }

    function getGrid(uint256 _gridId) internal view returns (uint256, bool, uint256, bool) {
        return (grid[_gridId].citadelId, grid[_gridId].isCapital, grid[_gridId].sovereignUntil, grid[_gridId].isLit);
    }

    function getGridFromCitadel(uint256 _citadelId) internal view returns (uint256) {
        if(citadel[_citadelId].gridId == 0) {
            return _citadelId;
        }
        return citadel[_citadelId].gridId;
    }

    function claim(uint256 _citadelId) public returns (uint256) {
        checkAccess();
        return claimInternal(_citadelId);
    }

    function claimInternal(uint256 _citadelId) internal returns (uint256) {
        require((citadel[_citadelId].timeOfLastClaim + claimInterval) < block.timestamp, "one claim per interval permitted");
        uint256 drakmaToClaim = combatEngine.calculateMiningOutput(
            _citadelId, 
            getGridFromCitadel(_citadelId), 
            getMiningStartTime()
        ) + citadel[_citadelId].unclaimedDrakma;
        
        citadel[_citadelId].timeOfLastClaim = block.timestamp;
        citadel[_citadelId].unclaimedDrakma = 0;
        if (!combatEngine.isTreasuryMaxed(capital[citadel[_citadelId].capitalId].treasury)) {
            capital[citadel[_citadelId].capitalId].treasury += (drakmaToClaim / 10);
            return (drakmaToClaim * 9) / 10;
        }
        return (drakmaToClaim / 10);
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) public {
        checkAccess();
        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train"
        );

        // allocate 100 sifGattaca on first train
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].stationedFleet.sifGattaca = 100;
            fleet[_citadelId].isValue = true;
        }

        fleet[_citadelId].trainingStarted = block.timestamp;
        fleet[_citadelId].trainingDone = block.timestamp + combatEngine.calculateTrainingTime(_sifGattaca, _mhrudvogThrot, _drebentraakht);
        fleet[_citadelId].trainingFleet.sifGattaca = _sifGattaca;
        fleet[_citadelId].trainingFleet.mhrudvogThrot = _mhrudvogThrot;
        fleet[_citadelId].trainingFleet.drebentraakht = _drebentraakht;
    }


    function resolveTraining(uint256 _citadelId) internal {
        if(fleet[_citadelId].trainingDone <= block.timestamp) {
            fleet[_citadelId].trainingDone = 0;
            fleet[_citadelId].trainingStarted = 0;
            fleet[_citadelId].stationedFleet.sifGattaca += fleet[_citadelId].trainingFleet.sifGattaca;
            fleet[_citadelId].trainingFleet.sifGattaca = 0;
            fleet[_citadelId].stationedFleet.mhrudvogThrot += fleet[_citadelId].trainingFleet.mhrudvogThrot;
            fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;
            fleet[_citadelId].stationedFleet.drebentraakht += fleet[_citadelId].trainingFleet.drebentraakht;
            fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function getMiningStartTime() internal view returns(uint256) {
        if(block.timestamp - claimInterval < gameStart) {
            return gameStart;
        }

        return block.timestamp - claimInterval;
    }

    /*
        _fleet param
        [0] _sifGattaca, 
        [1] _mhrudvogThrot, 
        [2] _drebentraakht

        _fleet calculated
        [3] _totalSifGattaca, 
        [4] _totalMhrudvogThrot, 
        [5] _totalDrebentraakht
    */
    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) public returns (uint256) {
        checkAccess();
        if(citadel[_fromCitadel].capitalId != citadel[_toCitadel].capitalId) {
            require(grid[citadel[_toCitadel].gridId].sovereignUntil < block.timestamp, "cannot siege");
        }

        resolveFleet(_fromCitadel);
        validateFleet(_fromCitadel, _fleet);

        // siege immediate when subgrid open
        (uint256 timeSiegeHits, uint256 gridDistance) = combatEngine.calculateGridTraversal(
            citadel[_fromCitadel].gridId, citadel[_toCitadel].gridId
        );

        require(timeSiegeHits > citadel[_toCitadel].timeLastSieged + 1 days, "cannot siege");

        if (_pilotId != 0) {
            require(gridDistance == 1, "cannot siege");
            bool pilotFound = false;
            for (uint256 j; j < citadel[_fromCitadel].pilot.length; ++j) {
                if(_pilotId == citadel[_fromCitadel].pilot[j]) {
                    pilotFound = true;
                    break;
                }
            }
            require(pilotFound == true, "cannot siege");
        }

        siege[_fromCitadel] = Siege(
            _toCitadel, 
            Fleet(_fleet[0], 
            _fleet[1], 
            _fleet[2]), 
            _pilotId, timeSiegeHits
        );

        fleet[_fromCitadel].stationedFleet.sifGattaca -= _fleet[0];
        fleet[_fromCitadel].stationedFleet.mhrudvogThrot -= _fleet[1];
        fleet[_fromCitadel].stationedFleet.drebentraakht -= _fleet[2];

        if (gridDistance <= combatEngine.subgridDistortion()) {
            return resolveSiege(_fromCitadel);
        }
        return 0;
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
            [0] = siege[_fromCitadel].fleet.sifGattaca
            [1] = siege[_fromCitadel].fleet.mhrudvogThrot
            [2] = siege[_fromCitadel].fleet.drebentraakht
            [3] = defendingSifGattaca
            [4] = defendingMhrudvogThrot
            [5] = defendingDrebentraakht
    */
    function resolveSiege(uint256 _fromCitadel) public returns (uint256) {
        checkAccess();
        require(
            siege[_fromCitadel].timeSiegeHits <= block.timestamp,
            "cannot resolve siege"
        );
        uint256 toCitadel = siege[_fromCitadel].toCitadel;
        resolveFleet(_fromCitadel);
        resolveFleet(toCitadel);
        // if left on grid 24 hours from hit time, fleet to defenders defect
        if(block.timestamp > (siege[_fromCitadel].timeSiegeHits + siegeMaxExpiry)) {
            fleet[toCitadel].stationedFleet.sifGattaca += siege[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].stationedFleet.mhrudvogThrot += siege[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].stationedFleet.drebentraakht += siege[_fromCitadel].fleet.drebentraakht;
            delete siege[_fromCitadel];

            // transfer 10% of siegeing dk to wallet who resolved
            uint256 drakmaFeeAvailable = combatEngine.calculateMiningOutput(
                _fromCitadel, 
                citadel[_fromCitadel].gridId, 
                getMiningStartTime(_fromCitadel)
            ) + citadel[_fromCitadel].unclaimedDrakma;
            return (drakmaFeeAvailable / 10);
        }
        uint256[6] memory tempTracker;
        (
            tempTracker[3], 
            tempTracker[4], 
            tempTracker[5]
        ) = getCitadelFleetCount(toCitadel);

        tempTracker[0] = uint256(siege[_fromCitadel].fleet.sifGattaca);
        tempTracker[1] = uint256(siege[_fromCitadel].fleet.mhrudvogThrot);
        tempTracker[2] = uint256(siege[_fromCitadel].fleet.drebentraakht);

        uint256 offensiveWinRatio;
        uint256[6] memory fleetTracker;
        (
            fleetTracker[0],
            fleetTracker[1],
            fleetTracker[2],
            fleetTracker[3],
            fleetTracker[4],
            fleetTracker[5],
            offensiveWinRatio
        ) = combatEngine.calculateDestroyedFleet(
            siege[_fromCitadel].pilot, 
            citadel[toCitadel].pilot,
            tempTracker,
            toCitadel
        );

        // update fleet count of defender
        fleet[toCitadel].stationedFleet.sifGattaca -= fleetTracker[3];
        fleet[toCitadel].stationedFleet.mhrudvogThrot -= fleetTracker[4];
        fleet[toCitadel].stationedFleet.drebentraakht -= fleetTracker[5];

        // return fleet and empty siege
        fleet[_fromCitadel].stationedFleet.sifGattaca += 
            (siege[_fromCitadel].fleet.sifGattaca - fleetTracker[0]);
        fleet[_fromCitadel].stationedFleet.mhrudvogThrot += 
            (siege[_fromCitadel].fleet.mhrudvogThrot - fleetTracker[1]);
        fleet[_fromCitadel].stationedFleet.drebentraakht += 
            (siege[_fromCitadel].fleet.drebentraakht - fleetTracker[2]);

        // handle grid usurper
        if (siege[_fromCitadel].pilot != 0) {
            if (offensiveWinRatio >= 80) {
                if (citadel[toCitadel].marker >= 2) {
                    citadel[_fromCitadel].marker = 0;
                    citadel[toCitadel].marker = 0;
                    swapGrid(citadel[_fromCitadel].gridId, getGridFromCitadel(toCitadel));
                } else {
                    citadel[toCitadel].marker += 1;
                }
            } else {
                citadel[toCitadel].marker = 0;
            }
        }

        // calculate dk to tx
        uint256 drakmaAvailable = combatEngine.calculateMiningOutput(
            toCitadel, 
            citadel[toCitadel].gridId, 
            getMiningStartTime(toCitadel)
        ) + citadel[toCitadel].unclaimedDrakma;

        uint256 drakmaCarry = (
            ((uint256(siege[_fromCitadel].fleet.sifGattaca) - fleetTracker[0]) * sifGattacaCary) +
            ((uint256(siege[_fromCitadel].fleet.mhrudvogThrot) - fleetTracker[1]) * mhrudvogThrotCary) +
            ((uint256(siege[_fromCitadel].fleet.drebentraakht) - fleetTracker[2]) * drebentraakhtCary)
        );

        uint256 dkToTransfer = drakmaAvailable > drakmaCarry ? drakmaCarry : drakmaAvailable;
        
        citadel[toCitadel].unclaimedDrakma = (drakmaAvailable - dkToTransfer);
        citadel[_fromCitadel].unclaimedDrakma += (dkToTransfer * 9) / 10;
        citadel[toCitadel].timeLastSieged = block.timestamp;
        
        delete siege[_fromCitadel];

        emit DispatchSiege(
            _fromCitadel,
            toCitadel,
            siege[_fromCitadel].timeSiegeHits,
            drakmaCarry,
            dkToTransfer,
            fleetTracker[0],
            fleetTracker[1],
            fleetTracker[2],
            fleetTracker[3],
            fleetTracker[4],
            fleetTracker[5]
        );

        return (dkToTransfer / 10);
    }

    function resolveFleet(uint256 _fromCitadel) internal {
        resolveTraining(_fromCitadel);
        if(reinforcements[_fromCitadel].fleetArrivalTime <= block.timestamp) {
            uint256 toCitadel = reinforcements[_fromCitadel].toCitadel;
            fleet[toCitadel].stationedFleet.sifGattaca += reinforcements[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].stationedFleet.mhrudvogThrot += reinforcements[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].stationedFleet.drebentraakht += reinforcements[_fromCitadel].fleet.drebentraakht;
            delete reinforcements[_fromCitadel];
        }
    }

    function validateFleet(
        uint256 _fromCitadel, 
        uint256[3] calldata _fleet
    ) internal view {
        uint256[3] memory totalFleet;
        (
            totalFleet[0],
            totalFleet[1],
            totalFleet[2]
        ) = getCitadelFleetCount(_fromCitadel);

        require(
            _fleet[0] <= totalFleet[0] &&
            _fleet[1] <= totalFleet[1] &&
            _fleet[2] <= totalFleet[2],
            "cannot send more fleet than in citadel"
        );
    }

    function sendReinforcements(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256[3] calldata _fleet
    ) public {
        checkAccess();
        resolveFleet(_fromCitadel);
        require(reinforcements[_fromCitadel].fleetArrivalTime == 0, "cannot reinforce");
        validateFleet(_fromCitadel, _fleet);

        (uint256 fleetArrivalTime, ) = combatEngine.calculateGridTraversal(_fromCitadel, _toCitadel);

        reinforcements[_fromCitadel].fleetArrivalTime = fleetArrivalTime;
        reinforcements[_fromCitadel].toCitadel = _toCitadel;
        reinforcements[_fromCitadel].fleet.sifGattaca = _fleet[0];
        reinforcements[_fromCitadel].fleet.mhrudvogThrot = _fleet[1];
        reinforcements[_fromCitadel].fleet.drebentraakht = _fleet[2];
        fleet[_fromCitadel].stationedFleet.sifGattaca -= _fleet[0];
        fleet[_fromCitadel].stationedFleet.mhrudvogThrot -= _fleet[1];
        fleet[_fromCitadel].stationedFleet.drebentraakht -= _fleet[2];
    }

    function bribeCapital(uint256 _citadelId, uint8 _capitalId) public returns (uint256) {
        checkAccess();
        require(!combatEngine.isTreasuryMaxed(capital[citadel[_citadelId].capitalId].treasury), "cannot bribe");
        require(grid[citadel[_citadelId].gridId].sovereignUntil != 0, "cannot bribe");
        citadel[_citadelId].capitalId = _capitalId;
        capital[_capitalId].treasury += capital[_capitalId].bribeAmt;
        grid[citadel[_citadelId].gridId].sovereignUntil += 64 days;
        
        return capital[_capitalId].bribeAmt;
    }

    function overthrowSovereign(uint256 _fromCitadelId, uint256 _toCitadelId, uint8 _capitalId) public returns (uint256) {
        checkAccess();
        uint256 fromGridId = getGridFromCitadel(_fromCitadelId);
        uint256 toGridId = getGridFromCitadel(_toCitadelId);
        require(grid[toGridId].sovereignUntil < block.timestamp, "cannot overthrow");

        swapGrid(fromGridId, toGridId);
        grid[toGridId].sovereignUntil = block.timestamp + 64 days;

        return (capital[_capitalId].bribeAmt * 2);
    }

    function sackCapital(uint256 _citadelId, uint8 _capitalId, uint256 bribeAmt, string calldata name) public returns (uint256) {
        checkAccess();
        require(citadel[_citadelId].gridId == capital[_capitalId].gridId, "cannot sack");
        require(capital[_capitalId].lastSack <= block.timestamp + 8 days, "cannot sack");
        capital[_capitalId].bribeAmt = bribeAmt;
        capital[_capitalId].name = name;

        return capital[_capitalId].treasury;
    }

    function checkAccess() internal view {
        require(msg.sender == accessAddress, "cannot call function directly");
    }

    function getCitadelFleetCount(uint256 _citadelId) public view returns (
        uint256, uint256, uint256
    ) {
        uint256[3] memory fleetArr;
        fleetArr[0] = fleet[_citadelId].stationedFleet.sifGattaca;
        fleetArr[1] = fleet[_citadelId].stationedFleet.mhrudvogThrot;
        fleetArr[2] = fleet[_citadelId].stationedFleet.drebentraakht;

        (
            uint256 trainedSifGattaca, 
            uint256 trainedMhrudvogThrot, 
            uint256 trainedDrebentraakht
        ) = combatEngine.calculateTrainedFleet(
            fleetArr, 
            fleet[_citadelId].trainingStarted, 
            fleet[_citadelId].trainingDone
        );

        return (
            fleetArr[0] + trainedSifGattaca, 
            fleetArr[1] + trainedMhrudvogThrot, 
            fleetArr[2] + trainedDrebentraakht
        );
    }

    function getMiningStartTime(uint256 _citadelId) internal view returns(uint256) {
        uint256 miningStartTime = citadel[_citadelId].timeOfLastClaim == 0 ? citadel[_citadelId].timeLit : citadel[_citadelId].timeOfLastClaim;
        miningStartTime = citadel[_citadelId].timeLastSieged > miningStartTime ? citadel[_citadelId].timeLastSieged : miningStartTime;
        return miningStartTime;
    }

    function getSiege(uint256 _fromCitadelId) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
                siege[_fromCitadelId].toCitadel,
                siege[_fromCitadelId].fleet.sifGattaca,
                siege[_fromCitadelId].fleet.mhrudvogThrot,
                siege[_fromCitadelId].fleet.drebentraakht,
                siege[_fromCitadelId].pilot,
                siege[_fromCitadelId].timeSiegeHits
        );
    }

    function getCapital(uint8 _capitalId) external view returns (uint256, uint256, uint256, string memory, uint256) {
        return (
                capital[_capitalId].gridId,
                capital[_capitalId].treasury,
                capital[_capitalId].bribeAmt,
                capital[_capitalId].name,
                grid[capital[_capitalId].gridId].citadelId
        );
    }

    // only owner
    function updateAccessAddress(address _accessAddress) external onlyOwner {
        accessAddress = _accessAddress;
    }
    
}


