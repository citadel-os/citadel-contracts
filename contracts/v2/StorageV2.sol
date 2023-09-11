// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        uint256[] memory _offensivePilotIds,
        uint256[] memory _defensivePilotIds,
        uint256[7] memory _fleetTracker
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function subgridDistortion() external view returns (uint256);
    function gridTraversalTime() external view returns (uint256);
    function calculateGridTraversal(
        uint256 _gridA, 
        uint256 _gridB
    ) external view returns (uint256, uint256);
}


contract StorageV2 is Ownable {
    using SafeERC20 for IERC20;

    // imports
    ICOMBATENGINE public immutable combatEngine;

    // data structures
    struct CitadelGrid {
        uint256 gridId;
        uint8 factionId;
        uint256 timeOfLastClaim;
        uint256 timeLit;
        uint256 timeLastRaided;
        uint256 unclaimedDrakma;
        uint256[] pilot;
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

    struct Raid {
        uint256 toCitadel;
        Fleet fleet;
        uint256[] pilot;
        uint256 timeRaidHits;
    }

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

    // mappings
    mapping(uint256 => CitadelGrid) citadel; // index is _citadelId
    mapping(uint256 => FleetAcademy) fleet; // index is _citadelId

    mapping(uint256 => Raid) raids; // index is _fromCitadelId
    mapping(uint256 => FleetReinforce) reinforcements; // index is _fromCitadelId
    mapping(uint256 => bool) pilot; // index is _pilotId

    uint256[] grid = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,797,798,799,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,881,882,883,884,885,886,887,888,889,890,891,892,893,894,895,896,897,898,899,900,901,902,903,904,905,906,907,908,909,910,911,912,913,914,915,916,917,918,919,920,921,922,923,924,925,926,927,928,929,930,931,932,933,934,935,936,937,938,939,940,941,942,943,944,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969,970,971,972,973,974,975,976,977,978,979,980,981,982,983,984,985,986,987,988,989,990,991,992,993,994,995,996,997,998,999,1000,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023];

    //variables
    uint256 gameStart;
    uint256 sifGattacaCary = 10000000000000000000;
    uint256 mhrudvogThrotCary = 2000000000000000000;
    uint256 drebentraakhtCary = 400000000000000000000;
    uint256 sifGattacaTrainingTime = 5 minutes;
    uint256 mhrudvogThrotTrainingTime = 15 minutes;
    uint256 drebentraakhtTrainingTime = 1 hours;
    uint256 raidMaxExpiry = 24 hours;
    uint256 claimInterval = 64 days;
    address accessAddress;


    constructor(
        ICOMBATENGINE _combatEngine
    ) {
        combatEngine = _combatEngine;
        gameStart = block.timestamp;
    }

    // public functions
    function liteGrid(uint256[] calldata _pilotIds, uint256 _gridId, uint8 _factionId) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        uint256 citadelId = grid[_gridId];

        for (uint256 i; i < _pilotIds.length; ++i) {
            require(!pilot[_pilotIds[i]], "pilot already lit");
            citadel[citadelId].pilot.push(_pilotIds[i]);
            pilot[_pilotIds[i]] = true;
        }

        if(citadel[citadelId].timeLit == 0) {
            citadel[citadelId].timeLit = block.timestamp;
            citadel[citadelId].gridId = _gridId;
            citadel[citadelId].factionId = _factionId;
        }
    }

    function dimGrid(uint256 _citadelId, uint256 _pilotId) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        for (uint256 i; i < citadel[_citadelId].pilot.length; ++i) {
            if (citadel[_citadelId].pilot[i] == _pilotId) {
                removePilot(i, _citadelId);
                break;
            }
        }
        pilot[_pilotId] = false;

        if (citadel[_citadelId].pilot.length == 0) {
            citadel[_citadelId].factionId = 0;
            citadel[_citadelId].timeOfLastClaim = 0;
            citadel[_citadelId].timeLit = 0;
        }
    }

    function removePilot(uint256 _index, uint256 _citadelId) internal {
        if (_index >= citadel[_citadelId].pilot.length) return;

        for (uint256 i = _index; i<citadel[_citadelId].pilot.length-1; i++){
            citadel[_citadelId].pilot[i] = citadel[_citadelId].pilot[i+1];
        }
        citadel[_citadelId].pilot.pop();
    }

    function claim(uint256 _citadelId) public returns (uint256) {
        require(msg.sender == accessAddress, "cannot call function directly");
        return claimInternal(_citadelId);
    }

    function claimInternal(uint256 _citadelId) internal returns (uint256) {
        require((citadel[_citadelId].timeOfLastClaim + claimInterval) < block.timestamp, "one claim per interval permitted");
        uint256 drakmaToClaim = combatEngine.calculateMiningOutput(
            _citadelId, 
            citadel[_citadelId].gridId, 
            getMiningStartTime()
        ) + citadel[_citadelId].unclaimedDrakma;
        
        citadel[_citadelId].timeOfLastClaim = block.timestamp;
        citadel[_citadelId].unclaimedDrakma = 0;
        return drakmaToClaim;
    }

    function trainFleet(uint256 _citadelId, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) public {
        require(msg.sender == accessAddress, "cannot call function directly");
        resolveTraining(_citadelId);
        require(
            fleet[_citadelId].trainingDone == 0,
            "cannot train new fleet until previous has finished"
        );

        uint256 timeTrainingDone = calculateTrainingTime(_sifGattaca, _mhrudvogThrot, _drebentraakht);


        // allocate 100 sifGattaca on first train
        if(!fleet[_citadelId].isValue) {
            fleet[_citadelId].stationedFleet.sifGattaca = 100;
            fleet[_citadelId].isValue = true;
        }

        fleet[_citadelId].trainingStarted = block.timestamp;
        fleet[_citadelId].trainingDone = timeTrainingDone;
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
    function sendRaid(
        uint256 _fromCitadel, 
        uint256 _toCitadel, 
        uint256[] calldata _pilot, 
        uint256[] calldata _fleet
    ) public returns (uint256) {
        require(msg.sender == accessAddress, "cannot call function directly");

        uint256[] memory totalFleet;
        resolveFleet(_fromCitadel);
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

        bool pilotFound = false;
        for (uint256 i; i < _pilot.length; ++i) {
            pilotFound = false;
            for (uint256 j; j < citadel[_fromCitadel].pilot.length; ++j) {
                if(_pilot[i] == citadel[_fromCitadel].pilot[j]) {
                    pilotFound = true;
                    break;
                }
            }
            require(pilotFound == true, "pilot sent must be lit to raiding citadel");
        }

        // raids immediate when subgrid open
        (uint256 timeRaidHits, uint256 gridDistance) = combatEngine.calculateGridTraversal(
            citadel[_fromCitadel].gridId, citadel[_toCitadel].gridId
        );

        raids[_fromCitadel] = Raid(
            _toCitadel, 
            Fleet(_fleet[0], 
            _fleet[1], 
            _fleet[2]), 
            _pilot, timeRaidHits
        );

        fleet[_fromCitadel].stationedFleet.sifGattaca -= _fleet[0];
        fleet[_fromCitadel].stationedFleet.mhrudvogThrot -= _fleet[1];
        fleet[_fromCitadel].stationedFleet.drebentraakht -= _fleet[2];

        if (gridDistance <= combatEngine.subgridDistortion()) {
            return resolveRaidInternal(_fromCitadel);
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
            [0] = raids[_fromCitadel].fleet.sifGattaca
            [1] = raids[_fromCitadel].fleet.mhrudvogThrot
            [2] = raids[_fromCitadel].fleet.drebentraakht
            [3] = toCitadel
            [4] = defendingSifGattaca
            [5] = defendingMhrudvogThrot
            [6] = defendingDrebentraakht
    */
    function resolveRaidInternal(uint256 _fromCitadel) internal returns (uint256) {
        require(
            raids[_fromCitadel].timeRaidHits <= block.timestamp,
            "cannot resolve a raid before it hits"
        );
        uint256 toCitadel = raids[_fromCitadel].toCitadel;
        resolveFleet(toCitadel);
        // if left on grid 24 hours from hit time, fleet to defenders defect
        if(block.timestamp > (raids[_fromCitadel].timeRaidHits + raidMaxExpiry)) {
            fleet[toCitadel].stationedFleet.sifGattaca += raids[_fromCitadel].fleet.sifGattaca;
            fleet[toCitadel].stationedFleet.mhrudvogThrot += raids[_fromCitadel].fleet.mhrudvogThrot;
            fleet[toCitadel].stationedFleet.drebentraakht += raids[_fromCitadel].fleet.drebentraakht;
            delete raids[_fromCitadel];

            // transfer 10% of raiding dk to wallet who resolved
            uint256 drakmaFeeAvailable = combatEngine.calculateMiningOutput(
            _fromCitadel, 
            citadel[_fromCitadel].gridId, 
            getMiningStartTime(_fromCitadel)
        ) + citadel[_fromCitadel].unclaimedDrakma;
            return (drakmaFeeAvailable / 10);
        }
        
        uint256[3] memory defendingFleetTracker;
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
        fleet[toCitadel].stationedFleet.sifGattaca -= fleetTracker[3];
        fleet[toCitadel].stationedFleet.mhrudvogThrot -= fleetTracker[4];
        fleet[toCitadel].stationedFleet.drebentraakht -= fleetTracker[5];

        // return fleet and empty raid
        fleet[_fromCitadel].stationedFleet.sifGattaca -= 
            (raids[_fromCitadel].fleet.sifGattaca - fleetTracker[0]);
        fleet[_fromCitadel].stationedFleet.mhrudvogThrot -= 
            (raids[_fromCitadel].fleet.mhrudvogThrot - fleetTracker[1]);
        fleet[_fromCitadel].stationedFleet.drebentraakht -= 
            (raids[_fromCitadel].fleet.drebentraakht - fleetTracker[2]);

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
        
        citadel[toCitadel].unclaimedDrakma = (drakmaAvailable - dkToTransfer);
        citadel[_fromCitadel].unclaimedDrakma += (dkToTransfer * 9) / 10;
        citadel[toCitadel].timeLastRaided = block.timestamp;

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

    function getCitadelFleetCount(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        (
            uint256 sifGattaca, 
            uint256 mhrudvogThrot, 
            uint256 drebentraakht
        ) = getTrainedFleet(_citadelId);

        return (
            sifGattaca + fleet[_citadelId].stationedFleet.sifGattaca,
            mhrudvogThrot + fleet[_citadelId].stationedFleet.mhrudvogThrot,
            drebentraakht + fleet[_citadelId].stationedFleet.drebentraakht
        );
    }

    function getTrainedFleet(uint256 _citadelId) public view returns (
        uint256, uint256, uint256
    ) {
        uint256 sifGattaca = fleet[_citadelId].stationedFleet.sifGattaca;
        uint256 mhrudvogThrot = fleet[_citadelId].stationedFleet.mhrudvogThrot;
        uint256 drebentraakht = fleet[_citadelId].stationedFleet.drebentraakht;

        (
            uint256 trainedSifGattaca, 
            uint256 trainedMhrudvogThrot, 
            uint256 trainedDrebentraakht
        ) = calculateTrainedFleet(_citadelId);

        return (
            sifGattaca + trainedSifGattaca, 
            mhrudvogThrot + trainedMhrudvogThrot, 
            drebentraakht + trainedDrebentraakht
        );
    }

    function calculateTrainedFleet(uint256 _citadelId) public view returns (uint256, uint256, uint256) {
        if(fleet[_citadelId].trainingDone <= block.timestamp) {
            return(
                fleet[_citadelId].trainingFleet.sifGattaca, 
                fleet[_citadelId].trainingFleet.mhrudvogThrot, 
                fleet[_citadelId].trainingFleet.drebentraakht
            );
        }

        uint256 sifGattacaTrained = 0;
        uint256 mhrudvogThrotTrained = 0;
        uint256 drebentraakhtTrained = 0;
        uint256 timeHolder = fleet[_citadelId].trainingStarted;

        sifGattacaTrained = (block.timestamp - timeHolder) / sifGattacaTrainingTime > fleet[_citadelId].trainingFleet.sifGattaca 
            ? fleet[_citadelId].trainingFleet.sifGattaca 
            : (block.timestamp - timeHolder) / sifGattacaTrainingTime;
        
        if(sifGattacaTrained == fleet[_citadelId].trainingFleet.sifGattaca) {
            timeHolder += (sifGattacaTrainingTime * sifGattacaTrained);
            mhrudvogThrotTrained = (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime > fleet[_citadelId].trainingFleet.mhrudvogThrot
                ? fleet[_citadelId].trainingFleet.mhrudvogThrot 
                : (block.timestamp - timeHolder) / mhrudvogThrotTrainingTime;
        }

        if(mhrudvogThrotTrained == fleet[_citadelId].trainingFleet.mhrudvogThrot) {
            timeHolder += (mhrudvogThrotTrainingTime * mhrudvogThrotTrained);
            drebentraakhtTrained = (block.timestamp - timeHolder) / drebentraakhtTrainingTime > fleet[_citadelId].trainingFleet.drebentraakht
                ? fleet[_citadelId].trainingFleet.drebentraakht
                : (block.timestamp - timeHolder) / drebentraakhtTrainingTime;
        }
        
        return (sifGattacaTrained, mhrudvogThrotTrained, drebentraakhtTrained);
    }

    function calculateTrainingTime(
        uint256 _sifGattaca, 
        uint256 _mhrudvogThrot, 
        uint256 _drebentraakht
    ) public view returns (uint256) {
        uint256 timeTrainingDone = block.timestamp;
        timeTrainingDone = _sifGattaca * sifGattacaTrainingTime;
        timeTrainingDone += _mhrudvogThrot * mhrudvogThrotTrainingTime;
        timeTrainingDone += _drebentraakht * drebentraakhtTrainingTime;

        return timeTrainingDone;
    }

    function getMiningStartTime(uint256 _citadelId) internal view returns(uint256) {
        uint256 miningStartTime = citadel[_citadelId].timeOfLastClaim == 0 ? citadel[_citadelId].timeLit : citadel[_citadelId].timeOfLastClaim;
        miningStartTime = citadel[_citadelId].timeLastRaided > miningStartTime ? citadel[_citadelId].timeLastRaided : miningStartTime;
        return miningStartTime;
    }

    // only owner
    function updateAccessAddress(address _accessAddress) external onlyOwner {
        accessAddress = _accessAddress;
    }
    
}


