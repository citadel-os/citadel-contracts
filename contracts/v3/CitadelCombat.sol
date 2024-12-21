// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondStorage.sol";
import "./interfaces/ICombat.sol";
import "./interfaces/ICombatEngine.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CitadelCombat is DiamondStorage, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable drakma;
    ICombatEngine public combatEngine;

    uint256 sifGattacaCary = 10000000000000000000;
    uint256 mhrudvogThrotCary = 2000000000000000000;
    uint256 drebentraakhtCary = 400000000000000000000;

    constructor(IERC20 _drakma, address _combatEngineAddress) {
        drakma = _drakma;
        combatEngine = ICombatEngine(_combatEngineAddress);
    }

    function sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) external nonReentrant {
        require(_fromCitadel != _toCitadel);
        //TODO ownership check

        uint256 dk = _sendSiege(_fromCitadel, _toCitadel, _pilotId, _fleet);
        if (dk > 0) {
            drakma.safeTransfer(msg.sender, dk);
        }

        emit CitadelEvent(_fromCitadel);
    }

    function resolveSiege(uint256 _fromCitadel) external nonReentrant {
        uint256 dkRake =  _resolveSiege(_fromCitadel);
        if (dkRake > 0) {
            drakma.safeTransfer(msg.sender, dkRake);
        }
        emit CitadelEvent(_fromCitadel);
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
    function _sendSiege(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) internal returns (uint256) {
        _resolveFleet(_fromCitadel);
        _validateFleet(_fromCitadel, _fleet);

        uint256 gridDistance = combatEngine.calculateGridTraversal(
            node[citadelNode[_fromCitadel].nodeId].gridId,
            node[citadelNode[_toCitadel].nodeId].gridId
        );

        uint256 timeSiegeHits = block.timestamp + gridDistance;

        require(timeSiegeHits > citadelNode[_toCitadel].timeLastSieged + 1 days, "cannot siege");

        if (_pilotId != 0) {
            require(gridDistance == 1, "cannot siege");
            bool pilotFound = false;
            for (uint256 j; j < citadelNode[_fromCitadel].pilot.length; ++j) {
                if(_pilotId == citadelNode[_fromCitadel].pilot[j]) {
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

        return 0;
    }

    function _resolveFleet(uint256 _fromCitadel) internal {
        _resolveTraining(_fromCitadel);
        if(reinforcements[_fromCitadel].fleetArrivalTime <= block.timestamp) {
            uint256 toCitadel = reinforcements[_fromCitadel].toCitadel;
            fleet[toCitadel].stationedFleet.sifGattaca += reinforcements[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].stationedFleet.mhrudvogThrot += reinforcements[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].stationedFleet.drebentraakht += reinforcements[_fromCitadel].fleet.drebentraakht;
            delete reinforcements[_fromCitadel];
        }
    }

    function _resolveTraining(uint256 _citadelId) internal {
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

    function _validateFleet(
        uint256 _fromCitadel, 
        uint256[3] calldata _fleet
    ) internal view {
        uint256[3] memory totalFleet;
        (
            totalFleet[0],
            totalFleet[1],
            totalFleet[2]
        ) = combatEngine.getCitadelFleetCount(_fromCitadel);

        require(
            _fleet[0] <= totalFleet[0] &&
            _fleet[1] <= totalFleet[1] &&
            _fleet[2] <= totalFleet[2],
            "cannot send more fleet than in citadel"
        );
    }

    function _resolveSiege(uint256 _fromCitadel) public returns (uint256) {
        require(
            siege[_fromCitadel].timeSiegeHits <= block.timestamp,
            "cannot resolve siege"
        );
        uint256 toCitadel = siege[_fromCitadel].toCitadel;
        _resolveFleet(_fromCitadel);
        _resolveFleet(toCitadel);
        // if left on grid 24 hours from hit time, fleet to defenders defect
        if(block.timestamp > (siege[_fromCitadel].timeSiegeHits + siegeMaxExpiry)) {
            fleet[toCitadel].stationedFleet.sifGattaca += siege[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].stationedFleet.mhrudvogThrot += siege[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].stationedFleet.drebentraakht += siege[_fromCitadel].fleet.drebentraakht;
            delete siege[_fromCitadel];

            // transfer 10% of siegeing dk to wallet who resolved
            uint256 drakmaFeeAvailable = combatEngine.calculateMiningOutput(
                _fromCitadel, 
                citadelNode[_fromCitadel].nodeId,
                _getMiningStartTime()
            ) + citadelNode[_fromCitadel].unclaimedDrakma;
            return (drakmaFeeAvailable / 10);
        }
        uint256[6] memory tempTracker;
        (
            tempTracker[3], 
            tempTracker[4], 
            tempTracker[5]
        ) = combatEngine.getCitadelFleetCount(toCitadel);

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
            citadelNode[toCitadel].pilot,
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
                if (citadelNode[toCitadel].marker >= 2) {
                    citadelNode[_fromCitadel].marker = 0;
                    citadelNode[toCitadel].marker = 0;
                    _swapNode(citadelNode[_fromCitadel].nodeId, citadelNode[toCitadel].nodeId);
                } else {
                    citadelNode[toCitadel].marker += 1;
                }
            } else {
                citadelNode[toCitadel].marker = 0;
            }
        }

        // calculate dk to tx
        uint256 drakmaAvailable = combatEngine.calculateMiningOutput(
            toCitadel, 
            citadelNode[toCitadel].nodeId,
            _getMiningStartTime()
        ) + citadelNode[toCitadel].unclaimedDrakma;

        uint256 drakmaCarry = (
            ((uint256(siege[_fromCitadel].fleet.sifGattaca) - fleetTracker[0]) * sifGattacaCary) +
            ((uint256(siege[_fromCitadel].fleet.mhrudvogThrot) - fleetTracker[1]) * mhrudvogThrotCary) +
            ((uint256(siege[_fromCitadel].fleet.drebentraakht) - fleetTracker[2]) * drebentraakhtCary)
        );

        uint256 dkToTransfer = drakmaAvailable > drakmaCarry ? drakmaCarry : drakmaAvailable;
        
        citadelNode[toCitadel].unclaimedDrakma = (drakmaAvailable - dkToTransfer);
        citadelNode[_fromCitadel].unclaimedDrakma += (dkToTransfer * 9) / 10;
        citadelNode[toCitadel].timeLastSieged = block.timestamp;
        
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

    // TODO include citadelId and time last claim?
    function _getMiningStartTime() internal view returns(uint256) {
        if(block.timestamp - claimInterval < gameStart) {
            return gameStart;
        }

        return block.timestamp - claimInterval;
    }

    function _swapNode(uint256 _fromNode, uint256 _toNode) internal {
        uint256 fromCitadelId = node[_fromNode].citadelId;
        uint256 toCitadelId = node[_toNode].citadelId;
        node[_fromNode].citadelId = toCitadelId;
        node[_toNode].citadelId = fromCitadelId;
        citadelNode[fromCitadelId].nodeId = _toNode;
        citadelNode[toCitadelId].nodeId = _fromNode;
    }

}