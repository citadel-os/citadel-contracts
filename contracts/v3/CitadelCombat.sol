// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondStorage.sol";
import "./interfaces/ICombat.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev CitadelCombat facet for EIP-2535 Diamond.
 *      We implement the ICombat interface for public functions
 *      and move all DiamondStorage references into this contract.
 */
contract CitadelCombat is ICombat, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ------------------------------------------
    // Events
    // ------------------------------------------
    event CitadelEvent(uint256 citadelId);
    event CitadelActionEvent(uint256 fromCitadelId, uint256 toCitadelId);

    // ------------------------------------------
    // Public (external) Combat Functions
    // ------------------------------------------
    function sendSiege(
        uint256 _fromCitadel,
        uint256 _toCitadel,
        uint256 _pilotId,
        uint256[3] calldata _fleet
    ) external override nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        require(_fromCitadel != _toCitadel, "Same citadel");
        // TODO: add an ownership check if needed (like requiring ds.citadelCollection.ownerOf(_fromCitadel) == msg.sender)

        uint256 dk = _sendSiege(ds, _fromCitadel, _toCitadel, _pilotId, _fleet);
        if (dk > 0) {
            ds.drakma.safeTransfer(msg.sender, dk);
        }

        emit CitadelEvent(_fromCitadel);
    }

    function resolveSiege(uint256 _fromCitadel) external override nonReentrant {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        uint256 dkRake = _resolveSiege(ds, _fromCitadel);
        if (dkRake > 0) {
            ds.drakma.safeTransfer(msg.sender, dkRake);
        }

        emit CitadelEvent(_fromCitadel);
    }

    // ------------------------------------------
    // NEW: Fleet Counting & Training Functions
    // ------------------------------------------

    /**
     * @dev Returns the total stationed fleet plus any partially trained amounts
     *      for the given citadel.
     */
    function getCitadelFleetCount(uint256 _citadelId)
        public
        view
        returns (uint256, uint256, uint256)
    {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        // Stationed (already trained) amounts
        uint256 sifGattaca = ds.fleet[_citadelId].stationedFleet.sifGattaca;
        uint256 mhrudvogThrot = ds.fleet[_citadelId].stationedFleet.mhrudvogThrot;
        uint256 drebentraakht = ds.fleet[_citadelId].stationedFleet.drebentraakht;

        // Partially trained amounts
        (
            uint256 trainedSifGattaca,
            uint256 trainedMhrudvogThrot,
            uint256 trainedDrebentraakht
        ) = calculateTrainedFleet(
            [sifGattaca, mhrudvogThrot, drebentraakht],
            ds.fleet[_citadelId].trainingStarted,
            ds.fleet[_citadelId].trainingDone
        );

        // Sum up stationed + partially trained
        return (
            sifGattaca + trainedSifGattaca,
            mhrudvogThrot + trainedMhrudvogThrot,
            drebentraakht + trainedDrebentraakht
        );
    }

    /**
     * @dev Calculates how many units are trained so far, based on the times
     *      for SifGattaca, MhrudvogThrot, Drebentraakht.
     *      If training is already completed, all units are effectively trained.
     */
    function calculateTrainedFleet(
        uint256[3] memory _fleet,
        uint256 _timeTrainingStarted,
        uint256 _timeTrainingDone
    ) public view returns (uint256, uint256, uint256) {
        DiamondStorage.GameStorage storage ds = DiamondStorage.diamondStorage();

        // If training is complete or no ongoing training
        if (_timeTrainingDone <= block.timestamp) {
            return (
                _fleet[0], 
                _fleet[1], 
                _fleet[2]
            );
        }

        // Track how many have been trained so far
        uint256 sifGattacaTrained = 0;
        uint256 mhrudvogThrotTrained = 0;
        uint256 drebentraakhtTrained = 0;

        // Start from trainingStarted
        uint256 timeHolder = _timeTrainingStarted;

        // 1) SifGattaca partial
        uint256 sifDuration = (block.timestamp > timeHolder)
            ? (block.timestamp - timeHolder)
            : 0;

        sifGattacaTrained = sifDuration / ds.sifGattacaTrainingTime;
        if (sifGattacaTrained > _fleet[0]) {
            sifGattacaTrained = _fleet[0];
        }

        // If we fully trained SifGattaca, proceed to MhrudvogThrot
        if (sifGattacaTrained == _fleet[0]) {
            timeHolder += (ds.sifGattacaTrainingTime * sifGattacaTrained);

            uint256 mhrDuration = (block.timestamp > timeHolder)
                ? (block.timestamp - timeHolder)
                : 0;

            mhrudvogThrotTrained = mhrDuration / ds.mhrudvogThrotTrainingTime;
            if (mhrudvogThrotTrained > _fleet[1]) {
                mhrudvogThrotTrained = _fleet[1];
            }

            // If we fully trained MhrudvogThrot, proceed to Drebentraakht
            if (mhrudvogThrotTrained == _fleet[1]) {
                timeHolder += (ds.mhrudvogThrotTrainingTime * mhrudvogThrotTrained);

                uint256 drebDuration = (block.timestamp > timeHolder)
                    ? (block.timestamp - timeHolder)
                    : 0;

                drebentraakhtTrained = drebDuration / ds.drebentraakhtTrainingTime;
                if (drebentraakhtTrained > _fleet[2]) {
                    drebentraakhtTrained = _fleet[2];
                }
            }
        }

        return (sifGattacaTrained, mhrudvogThrotTrained, drebentraakhtTrained);
    }

    // ------------------------------------------
    // Internal Logic (unchanged from your snippet)
    // ------------------------------------------

    function _sendSiege(
        DiamondStorage.GameStorage storage ds,
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256 _pilotId, 
        uint256[3] calldata _fleet
    ) internal returns (uint256) {
        _resolveFleet(ds, _fromCitadel);
        _validateFleet(_fromCitadel, _fleet);

        uint256 gridDistance = ds.combatEngine.calculateGridTraversal(
            ds.node[ds.citadelNode[_fromCitadel].nodeId].gridId,
            ds.node[ds.citadelNode[_toCitadel].nodeId].gridId,
            ds.gridTraversalTime
        );

        uint256 timeSiegeHits = block.timestamp + gridDistance;
        require(
            timeSiegeHits > ds.citadelNode[_toCitadel].timeLastSieged + 1 days, 
            "cannot siege yet"
        );

        if (_pilotId != 0) {
            require(gridDistance == 1, "cannot siege pilot > 1 distance");
            bool pilotFound = false;
            for (uint256 j; j < ds.citadelNode[_fromCitadel].pilot.length; ++j) {
                if (_pilotId == ds.citadelNode[_fromCitadel].pilot[j]) {
                    pilotFound = true;
                    break;
                }
            }
            require(pilotFound, "pilot not found");
        }

        ds.siege[_fromCitadel] = DiamondStorage.Siege(
            _toCitadel,
            DiamondStorage.Fleet(_fleet[0], _fleet[1], _fleet[2]),
            _pilotId,
            timeSiegeHits,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        ds.fleet[_fromCitadel].stationedFleet.sifGattaca -= _fleet[0];
        ds.fleet[_fromCitadel].stationedFleet.mhrudvogThrot -= _fleet[1];
        ds.fleet[_fromCitadel].stationedFleet.drebentraakht -= _fleet[2];

        return 0;
    }

    function _resolveSiege(
        DiamondStorage.GameStorage storage ds,
        uint256 _fromCitadel
    ) internal returns (uint256) {
        require(ds.siege[_fromCitadel].timeSiegeHits <= block.timestamp, "cannot resolve siege");

        uint256 toCitadel = ds.siege[_fromCitadel].toCitadel;
        _resolveFleet(ds, _fromCitadel);
        _resolveFleet(ds, toCitadel);

        // If left on grid 24 hours from hit time => defect
        if (block.timestamp > (ds.siege[_fromCitadel].timeSiegeHits + ds.siegeMaxExpiry)) {
            ds.fleet[toCitadel].stationedFleet.sifGattaca += ds.siege[_fromCitadel].fleet.sifGattaca;
            ds.fleet[toCitadel].stationedFleet.mhrudvogThrot += ds.siege[_fromCitadel].fleet.mhrudvogThrot;
            ds.fleet[toCitadel].stationedFleet.drebentraakht += ds.siege[_fromCitadel].fleet.drebentraakht;

            ds.siege[_fromCitadel].offensiveSifGattacaDestroyed = ds.siege[_fromCitadel].fleet.sifGattaca;
            ds.siege[_fromCitadel].offensiveMhrudvogThrotDestroyed = ds.siege[_fromCitadel].fleet.mhrudvogThrot;
            ds.siege[_fromCitadel].offensiveDrebentraakhtDestroyed = ds.siege[_fromCitadel].fleet.drebentraakht;

            // Transfer 10% of the siegeing Drakma
            uint256 drakmaFeeAvailable = _calculateMiningOutput(
                _fromCitadel, 
                ds.citadelNode[_fromCitadel].nodeId,
                _getMiningStartTime(ds)
            ) + ds.citadelNode[_fromCitadel].unclaimedDrakma;
            return (drakmaFeeAvailable / 10);
        }

        // Normal resolution
        uint256[6] memory tempTracker;
        (
            tempTracker[3],
            tempTracker[4],
            tempTracker[5]
        ) = getCitadelFleetCount(toCitadel);

        tempTracker[0] = ds.siege[_fromCitadel].fleet.sifGattaca;
        tempTracker[1] = ds.siege[_fromCitadel].fleet.mhrudvogThrot;
        tempTracker[2] = ds.siege[_fromCitadel].fleet.drebentraakht;

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
        ) = ds.combatEngine.calculateDestroyedFleet(
            ds.siege[_fromCitadel].pilot,
            ds.citadelNode[toCitadel].pilot,
            tempTracker,
            toCitadel
        );

        // Update defender's fleet
        ds.fleet[toCitadel].stationedFleet.sifGattaca -= fleetTracker[3];
        ds.fleet[toCitadel].stationedFleet.mhrudvogThrot -= fleetTracker[4];
        ds.fleet[toCitadel].stationedFleet.drebentraakht -= fleetTracker[5];

        // Return surviving attacker fleet
        ds.fleet[_fromCitadel].stationedFleet.sifGattaca += 
            (ds.siege[_fromCitadel].fleet.sifGattaca - fleetTracker[0]);
        ds.fleet[_fromCitadel].stationedFleet.mhrudvogThrot += 
            (ds.siege[_fromCitadel].fleet.mhrudvogThrot - fleetTracker[1]);
        ds.fleet[_fromCitadel].stationedFleet.drebentraakht += 
            (ds.siege[_fromCitadel].fleet.drebentraakht - fleetTracker[2]);

        // Possibly swap nodes
        if (ds.siege[_fromCitadel].pilot != 0 && offensiveWinRatio >= 80) {
            if (ds.citadelNode[toCitadel].marker >= 2) {
                ds.citadelNode[_fromCitadel].marker = 0;
                ds.citadelNode[toCitadel].marker = 0;
                _swapNode(ds, ds.citadelNode[_fromCitadel].nodeId, ds.citadelNode[toCitadel].nodeId);
            } else {
                ds.citadelNode[toCitadel].marker += 1;
            }
        } else {
            ds.citadelNode[toCitadel].marker = 0;
        }

        // Drakma carry
        uint256 drakmaAvailable = _calculateMiningOutput(
            toCitadel, 
            ds.citadelNode[toCitadel].nodeId,
            _getMiningStartTime(ds)
        ) + ds.citadelNode[toCitadel].unclaimedDrakma;

        uint256 drakmaCarry = (
            ((ds.siege[_fromCitadel].fleet.sifGattaca - fleetTracker[0]) * ds.sifGattacaCary) +
            ((ds.siege[_fromCitadel].fleet.mhrudvogThrot - fleetTracker[1]) * ds.mhrudvogThrotCary) +
            ((ds.siege[_fromCitadel].fleet.drebentraakht - fleetTracker[2]) * ds.drebentraakhtCary)
        );

        uint256 dkToTransfer = (drakmaAvailable > drakmaCarry) ? drakmaCarry : drakmaAvailable;
        ds.citadelNode[toCitadel].unclaimedDrakma = drakmaAvailable - dkToTransfer;
        ds.citadelNode[_fromCitadel].unclaimedDrakma += ((dkToTransfer * 9) / 10);
        ds.citadelNode[toCitadel].timeLastSieged = block.timestamp;

        ds.siege[_fromCitadel].offensiveCarryCapacity = drakmaCarry;
        ds.siege[_fromCitadel].drakmaSieged = dkToTransfer;

        ds.siege[_fromCitadel].offensiveSifGattacaDestroyed = fleetTracker[0];
        ds.siege[_fromCitadel].offensiveMhrudvogThrotDestroyed = fleetTracker[1];
        ds.siege[_fromCitadel].offensiveDrebentraakhtDestroyed = fleetTracker[2];
        ds.siege[_fromCitadel].defensiveSifGattacaDestroyed = fleetTracker[3];
        ds.siege[_fromCitadel].defensiveMhrudvogThrotDestroyed = fleetTracker[4];
        ds.siege[_fromCitadel].defensiveDrebentraakhtDestroyed = fleetTracker[5];

        emit CitadelActionEvent(_fromCitadel, toCitadel);
        return (dkToTransfer / 10);
    }

    function _resolveFleet(DiamondStorage.GameStorage storage ds, uint256 _fromCitadel) internal {
        _resolveTraining(ds, _fromCitadel);

        if (
            ds.reinforcements[_fromCitadel].fleetArrivalTime <= block.timestamp &&
            ds.reinforcements[_fromCitadel].fleetArrivalTime != 0
        ) {
            uint256 toCitadel = ds.reinforcements[_fromCitadel].toCitadel;
            ds.fleet[toCitadel].stationedFleet.sifGattaca += ds.reinforcements[_fromCitadel].fleet.sifGattaca;
            ds.fleet[toCitadel].stationedFleet.mhrudvogThrot += ds.reinforcements[_fromCitadel].fleet.mhrudvogThrot;
            ds.fleet[toCitadel].stationedFleet.drebentraakht += ds.reinforcements[_fromCitadel].fleet.drebentraakht;
            delete ds.reinforcements[_fromCitadel];
        }
    }

    function _resolveTraining(DiamondStorage.GameStorage storage ds, uint256 _citadelId) internal {
        if (
            ds.fleet[_citadelId].trainingDone <= block.timestamp &&
            ds.fleet[_citadelId].trainingDone != 0
        ) {
            ds.fleet[_citadelId].trainingDone = 0;
            ds.fleet[_citadelId].trainingStarted = 0;

            ds.fleet[_citadelId].stationedFleet.sifGattaca += ds.fleet[_citadelId].trainingFleet.sifGattaca;
            ds.fleet[_citadelId].trainingFleet.sifGattaca = 0;

            ds.fleet[_citadelId].stationedFleet.mhrudvogThrot += ds.fleet[_citadelId].trainingFleet.mhrudvogThrot;
            ds.fleet[_citadelId].trainingFleet.mhrudvogThrot = 0;

            ds.fleet[_citadelId].stationedFleet.drebentraakht += ds.fleet[_citadelId].trainingFleet.drebentraakht;
            ds.fleet[_citadelId].trainingFleet.drebentraakht = 0;
        }
    }

    function _validateFleet(
        uint256 _fromCitadel, 
        uint256[3] calldata _fleet
    ) internal view {
        (uint256 tSif, uint256 tMhr, uint256 tDreb) = getCitadelFleetCount(_fromCitadel);

        require(
            _fleet[0] <= tSif &&
            _fleet[1] <= tMhr &&
            _fleet[2] <= tDreb,
            "cannot send more fleet than in citadel"
        );
    }

    function _getMiningStartTime(DiamondStorage.GameStorage storage ds)
        internal
        view
        returns (uint256)
    {
        if (block.timestamp - ds.claimInterval < ds.gameStart) {
            return ds.gameStart;
        }
        return block.timestamp - ds.claimInterval;
    }

    function _swapNode(
        DiamondStorage.GameStorage storage ds,
        uint256 _fromNode,
        uint256 _toNode
    ) internal {
        uint256 fromCitadelId = ds.node[_fromNode].citadelId;
        uint256 toCitadelId = ds.node[_toNode].citadelId;
        ds.node[_fromNode].citadelId = toCitadelId;
        ds.node[_toNode].citadelId = fromCitadelId;
        ds.citadelNode[fromCitadelId].nodeId = _toNode;
        ds.citadelNode[toCitadelId].nodeId = _fromNode;
    }

    function _calculateMiningOutput(
        uint256 _citadelId, 
        uint256 _nodeId, 
        uint256 _lastClaimTime
    ) internal pure returns (uint256) {

        // TODO revisit
        return 1;
    }
}

