// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IPILOT {
    function getOnchainPILOT(uint256 tokenId) external view returns (bool, uint8);
}

contract CombatEngineV1 {
    IPILOT public immutable pilotCollection;

    // citadel props
    uint8[] shieldProp = [0,1,1,1,0,0,1,3,0,1,2,0,1,0,0,0,0,0,0,1,2,0,0,0,0,1,1,1,0,0,3,0,0,1,0,1,0,1,0,0,1,0,1,0,0,0,3,2,2,2,1,2,1,3,0,0,2,0,2,0,3,0,0,0,2,0,0,2,3,0,1,1,0,1,0,0,1,1,1,0,0,0,0,0,0,2,0,0,0,0,0,0,3,0,0,2,0,0,1,0,1,0,2,2,1,2,1,0,1,1,0,0,0,2,0,0,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,0,1,0,2,0,6,4,0,0,2,1,4,2,0,0,0,1,0,2,0,0,0,0,2,0,3,1,0,0,1,0,0,2,1,0,0,0,0,0,1,0,1,0,0,3,1,0,2,0,1,0,0,0,2,0,2,4,0,0,0,0,1,0,0,0,3,0,1,3,0,1,0,1,1,2,0,0,1,1,1,0,2,0,0,0,0,0,2,0,1,0,2,3,1,2,1,0,1,0,2,0,1,1,1,0,1,0,0,1,1,0,0,0,2,2,3,1,1,3,0,0,0,0,2,0,1,0,1,1,1,1,3,0,1,1,0,6,2,0,3,0,1,1,1,1,1,0,2,2,2,1,0,1,0,0,0,2,0,0,0,1,0,3,0,3,2,2,0,0,0,0,0,1,0,0,0,0,2,1,0,1,0,1,0,1,4,0,0,1,0,0,0,1,2,0,0,2,2,1,1,2,0,1,2,3,0,4,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,1,2,0,0,2,0,1,1,0,3,0,0,3,0,1,0,0,0,2,0,0,0,4,1,1,1,4,0,0,0,2,1,0,0,0,0,0,0,1,0,3,0,0,0,1,0,1,0,0,6,1,2,0,0,2,0,4,5,1,2,0,0,0,1,2,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,1,1,2,2,2,1,1,4,1,0,2,0,2,1,0,0,0,0,0,0,1,0,0,0,0,3,0,0,0,7,1,2,2,0,1,0,5,0,0,0,1,1,2,0,0,0,1,0,0,1,2,0,1,0,0,0,1,0,1,0,1,3,0,0,1,0,0,0,2,2,1,0,0,0,0,3,3,1,0,2,0,2,0,2,0,5,1,0,0,4,0,0,5,0,1,3,0,1,4,0,0,2,1,2,2,0,0,0,0,1,0,0,0,0,0,1,4,1,0,0,1,0,0,0,5,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,1,1,0,0,2,3,1,0,1,2,1,5,0,0,0,0,0,0,1,6,2,0,2,1,0,3,0,0,2,1,0,3,0,2,3,0,1,0,3,0,0,1,0,2,3,1,1,3,1,1,0,1,1,3,0,0,1,0,1,0,0,3,0,2,0,1,0,0,0,0,1,1,0,0,1,1,2,1,0,0,3,1,0,2,1,0,0,3,0,0,2,0,0,0,1,2,0,2,0,0,2,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1,1,2,0,1,3,1,2,0,0,1,3,0,0,0,0,0,1,2,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0,2,0,0,3,1,0,0,0,1,1,2,2,1,0,0,3,0,0,0,2,0,1,0,0,0,1,2,0,2,6,0,0,0,0,2,0,3,1,0,1,1,3,0,0,2,0,0,2,1,0,0,0,1,0,1,1,5,0,0,1,4,2,0,0,1,2,1,0,2,1,1,2,0,0,0,2,0,2,1,0,0,0,0,2,1,0,1,1,1,3,1,0,2,2,3,0,0,1,0,0,0,1,0,1,4,2,1,3,1,0,1,0,1,0,0,6,1,0,3,0,0,1,2,1,0,0,0,0,0,0,2,3,2,0,1,0,1,1,0,0,1,2,2,2,0,0,0,4,0,0,0,3,1,4,1,2,1,5,4,0,0,0,2,1,1,0,0,0,1,2,5,2,0,0,0,0,0,0,3,1,1,3,1,0,0,0,1,0,1,0,3,0,0,2,1,0,1,0,1,0,0,1,0,0,1,0,0,0,3,2,0,1,3,3,0,1,0,1,0,1,0,0,0,1,0,2,0,4,1,0,2,3,1,1,0,1,0,0,6,0,0,3,2,2,0,0,0,0,0,0,0,0,0,0,0,3,2,0,2,0,0,0,0,0,0,2,3,2,3,3,4,3,4,7,5,3,4,4,6,5,4,5,4,4,4,4,4,5,4,4,4,7,4,5,5,5,7];
    uint8[] engineProp = [1,0,1,4,1,0,0,0,1,0,0,1,0,1,0,0,0,2,1,0,0,1,0,3,0,0,0,0,1,1,0,3,1,1,0,1,0,0,0,0,1,0,3,0,1,0,0,3,0,0,3,1,0,0,0,2,0,1,1,0,1,0,0,0,0,0,0,1,7,0,2,1,3,0,0,5,1,0,0,1,0,0,1,1,1,0,0,0,0,1,0,0,3,1,2,0,0,4,0,1,0,3,2,0,0,0,0,0,1,0,0,0,0,0,0,0,3,2,1,0,0,2,0,2,0,1,0,1,0,1,1,0,5,1,0,3,1,0,0,3,0,1,1,1,1,0,0,6,1,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,2,0,0,0,4,0,2,0,5,5,0,2,6,3,0,0,1,0,0,4,0,1,2,1,1,2,1,0,0,2,7,2,0,2,0,2,0,0,1,0,2,5,0,1,4,0,0,0,0,0,1,1,2,1,0,2,1,0,4,1,4,0,1,2,2,0,0,1,0,0,0,0,1,0,2,1,1,0,4,0,1,1,2,1,1,0,1,0,1,0,1,2,3,0,0,0,0,1,3,1,0,2,0,2,0,3,0,0,1,0,6,0,0,1,0,0,2,1,0,0,1,1,0,1,2,1,1,1,1,0,0,0,0,4,0,2,0,1,1,5,0,1,2,2,3,2,2,0,3,1,5,1,1,0,0,1,1,3,2,0,0,0,0,0,0,0,0,0,0,3,0,0,0,2,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,1,2,0,1,0,2,1,0,2,3,0,2,0,0,0,1,0,0,4,1,0,0,0,4,0,0,0,4,4,1,5,0,0,1,2,1,1,1,0,2,1,1,1,3,2,0,2,0,0,1,0,0,0,0,0,1,2,0,3,1,0,3,0,0,0,0,0,1,1,0,0,1,1,1,0,0,0,1,0,2,0,1,2,0,1,1,0,0,0,2,0,1,0,2,1,2,1,0,1,0,3,0,2,0,1,3,1,0,0,0,0,1,3,0,0,1,0,1,4,1,0,1,0,1,1,1,2,0,0,0,3,1,1,2,1,2,0,2,2,4,0,0,2,3,2,0,0,0,0,0,2,1,0,4,1,1,0,0,0,0,0,2,0,0,0,0,1,1,1,0,0,0,1,3,1,0,1,3,1,0,4,2,1,0,0,1,1,0,1,1,0,2,0,2,0,2,2,0,1,0,0,0,0,1,2,0,0,2,2,1,1,1,2,0,5,0,0,0,0,0,1,0,1,0,0,1,2,0,2,4,5,1,0,2,0,0,0,4,0,6,3,2,2,0,1,0,1,4,0,0,1,0,0,0,0,1,1,0,0,1,1,0,0,3,0,0,3,1,1,0,0,2,0,2,1,2,0,3,0,1,0,2,1,0,0,4,3,2,0,1,2,0,1,0,0,4,0,2,0,3,3,0,1,0,0,0,1,1,0,2,0,3,1,0,0,1,0,3,1,4,0,3,0,0,4,1,1,1,0,0,3,0,0,0,0,2,0,0,0,4,1,0,0,0,0,0,2,1,3,0,0,0,0,2,0,0,0,2,1,0,3,0,0,1,0,1,0,2,0,0,0,0,1,0,1,1,1,5,5,2,0,2,0,0,0,0,0,1,3,1,0,1,0,2,0,0,0,2,1,2,1,2,2,0,5,1,1,0,0,3,2,0,1,0,0,1,0,2,1,0,3,0,0,3,2,1,1,1,2,0,0,0,1,0,1,2,0,1,2,0,0,1,0,1,3,2,5,0,0,0,0,0,3,2,0,0,4,1,1,0,0,3,0,2,0,0,0,1,2,2,0,1,2,1,2,0,6,0,1,0,1,2,2,2,0,2,0,0,0,3,4,1,1,1,1,4,0,0,2,2,0,2,2,0,1,0,0,0,1,1,0,3,1,0,3,0,3,2,2,0,1,0,1,5,1,0,0,3,0,0,2,0,0,1,4,1,1,1,0,1,0,0,3,0,0,3,1,0,0,0,1,2,0,0,0,0,0,2,2,0,0,0,0,0,4,5,4,2,0,1,0,1,2,0,2,0,2,0,1,0,0,1,1,2,0,0,0,0,2,1,1,0,2,0,0,0,0,0,0,1,0,1,0,0,1,0,0,3,0,4,1,1,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,3,0,0,0,0,0,0,0,3,3,3,6,6,6,7,7];
    uint8[] weaponsProp = [0,0,0,1,1,3,0,0,1,3,1,0,0,0,4,4,2,4,0,0,1,1,4,0,0,5,0,1,0,0,0,3,0,0,1,0,0,1,0,0,2,1,0,0,0,0,1,0,3,0,1,0,1,3,0,0,1,1,2,1,0,2,0,0,0,2,1,0,1,1,1,0,0,2,1,2,3,0,0,2,2,0,0,2,0,0,0,3,0,0,0,0,0,0,1,1,1,0,0,0,1,5,0,1,4,0,1,0,3,0,0,0,0,1,0,1,0,0,0,0,3,1,1,1,0,0,2,0,0,5,0,1,1,1,0,0,1,4,1,0,0,1,0,1,0,0,0,1,1,2,0,2,3,0,3,0,3,1,6,2,1,1,0,0,0,0,1,0,1,0,2,2,0,0,0,1,1,0,0,1,0,0,1,0,0,0,4,5,1,0,1,1,1,0,0,0,2,5,0,1,0,0,1,0,2,0,0,3,0,0,1,2,0,2,0,0,0,0,0,2,3,1,1,1,0,0,5,1,0,0,0,0,1,2,2,1,0,0,3,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,2,0,0,0,0,0,0,0,1,0,0,2,0,0,2,1,2,0,1,0,0,5,1,0,2,2,1,2,0,1,3,0,1,2,0,0,1,0,0,2,2,0,1,0,0,1,4,1,0,1,2,0,0,4,0,0,4,0,1,0,1,0,0,1,2,0,1,0,1,3,0,0,1,0,0,1,1,0,1,0,0,0,0,3,1,1,0,1,4,1,0,3,0,0,1,0,0,2,1,5,1,4,2,2,1,2,0,0,1,1,1,0,0,3,0,0,0,2,1,1,2,0,0,1,4,0,1,1,0,2,0,0,0,0,4,2,0,0,1,0,0,0,4,0,0,0,1,1,4,3,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,1,0,1,4,0,0,2,0,0,0,7,1,0,3,5,1,4,1,0,0,2,1,1,1,0,0,1,4,0,6,1,1,1,1,0,0,3,0,4,3,4,0,1,0,1,0,0,0,3,2,3,2,2,2,0,0,2,1,0,2,1,1,0,1,0,0,2,1,0,0,4,1,0,2,0,2,2,0,2,4,0,0,0,1,1,1,0,1,0,2,0,0,0,1,0,1,1,0,0,0,4,1,1,0,0,0,1,2,0,4,1,1,0,0,1,0,1,0,0,0,1,0,1,0,0,0,0,2,0,3,0,2,0,1,0,2,2,0,0,0,0,0,2,0,0,1,1,0,0,7,0,1,2,2,0,1,2,2,0,2,0,0,1,1,1,0,2,1,0,1,4,0,0,1,0,0,2,1,2,0,0,4,1,0,0,1,2,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,1,0,2,0,0,0,0,3,1,2,3,0,0,0,0,1,0,2,1,2,0,2,1,1,0,1,2,0,0,5,2,2,5,0,0,0,0,1,7,1,1,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,1,0,1,1,0,0,2,2,0,1,1,1,0,0,2,1,2,0,1,0,2,0,0,2,3,0,0,2,3,3,0,1,4,0,1,0,0,1,0,0,3,0,4,0,1,0,0,0,0,0,0,1,3,0,4,1,1,0,0,0,0,1,2,1,1,1,1,0,0,2,2,4,1,0,1,0,2,0,0,1,1,0,2,1,4,0,0,0,0,1,0,2,0,0,2,1,0,0,1,1,2,0,2,1,0,5,0,0,0,1,0,0,2,2,1,0,0,1,1,2,0,0,0,2,0,5,0,0,2,5,0,0,0,0,0,7,0,2,0,3,0,0,0,3,2,0,2,0,1,2,0,1,0,0,0,0,0,2,3,1,1,0,0,0,1,0,2,0,1,3,1,0,0,1,0,0,0,0,0,0,0,3,0,2,0,0,0,0,2,2,0,0,1,1,0,0,2,1,0,0,1,0,0,0,0,2,5,0,1,0,2,1,0,0,1,3,0,0,0,0,1,3,0,0,1,0,1,0,0,0,1,0,1,0,0,0,2,0,1,1,0,0,0,2,0,0,0,0,0,1,2,2,1,0,0,0,0,0,3,0,2,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,2,1,1,0,0,6,0,1,2,3,0,0,1,2,1,0,2,0,1,0,2,0,0,1,2,0,2,0,0,0,0,0,0,0,0,3,1,3,3,1,3,2,3,3,3,3,6,5,6,3,3,3,3,3,3,3,6,3,3,3,3,3,3,6,6];

    uint256 public baseMiningRatePerHour = 20000000000000000000; //20 DK base / hr
    uint8 public pilotMultiple = 20;
    uint8 public levelMultiple = 2;
    uint256 public sifGattacaOP = 10;
    uint256 public mhrudvogThrotOP = 5;
    uint256 public drebentraakhtOP = 500;
    uint256 public sifGattacaDP = 5;
    uint256 public mhrudvogThrotDP = 40;
    uint256 public drebentraakhtDP = 250;

    uint256 periodFinish = 1674943200; //JAN 28 2023, 2PM PT
    
    constructor(IPILOT _pilotCollection) {
        pilotCollection = _pilotCollection;
    }

    function combatOP(uint256 _citadelId, uint256[] memory _pilotIds, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) public view returns (uint256) {
        uint256 multiple = 0;

        for (uint256 i; i < _pilotIds.length; ++i) {
            (,uint8 level) = pilotCollection.getOnchainPILOT(_pilotIds[i]);
            multiple += pilotMultiple + (level * levelMultiple);
        }

        return (((
            (_sifGattaca * sifGattacaOP) +
            (_mhrudvogThrot * mhrudvogThrotOP) +
            (_drebentraakht * drebentraakhtOP)) 
            * (100 + multiple)) 
            / 100
        );
    }

    function combatDP(uint256 _citadelId, uint256[] memory _pilotIds, uint256 _sifGattaca, uint256 _mhrudvogThrot, uint256 _drebentraakht) public view returns (uint256) {
        uint256 swarmMultiple = 0;
        uint256 siegeMultiple = 0;
        uint256 multiple = 0;
        for (uint256 i; i < _pilotIds.length; ++i) {
            (,uint8 level) = pilotCollection.getOnchainPILOT(_pilotIds[i]);
            multiple += pilotMultiple + (level * levelMultiple);
        }

        multiple += calculateBaseCitadelMultiple(weaponsProp[_citadelId]);
        multiple += calculateBaseCitadelMultiple(shieldProp[_citadelId]);

        (swarmMultiple, siegeMultiple) = calculateUniqueBonus(weaponsProp[_citadelId], engineProp[_citadelId], shieldProp[_citadelId]);
        uint256 dp = ((
            (
                ((_sifGattaca * sifGattacaDP) * (100 + swarmMultiple) / 100) +
                (_mhrudvogThrot * mhrudvogThrotDP) +
                ((_drebentraakht * drebentraakhtDP) * (100 + siegeMultiple) / 100)
            ) 
            * (100 + multiple)) / 100
        );
        return dp;
    }

    function calculateMiningOutput(uint256 _citadelId, uint256 _gridId, uint256 lastClaimTime) public view returns (uint256) {
        uint256 miningMultiple = calculateMiningMultiple(engineProp[_citadelId], shieldProp[_citadelId]);
        return (
            ((lastTimeRewardApplicable() - lastClaimTime) *
                ((baseMiningRatePerHour * ((100 + getGridMultiple(_gridId)) / 100)) / 3600) *
                ((100 + miningMultiple) / 100))
        );
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
            siegeMultiple += 10;
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

    function calculateMiningMultiple(uint8 engine, uint8 shield) internal view returns (uint256) {
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

    function getGridMultiple(uint256 _gridId) public view returns (uint256) {
        uint8 multiple = 0;
        if(_gridId >= 410 && _gridId <= 615) {
            multiple = 10;
            if(_gridId >= 460 && _gridId <= 564) {
                multiple = 20; 
            }
            if(_gridId >= 487 && _gridId <= 537) {
                multiple = 25;
            }
        }
        
        return multiple;
    }

    function calculateGridDistance(uint256 _a, uint256 _b) public view returns (uint256) {

        return Math.sqrt(uint256((int(_a % 32) - int(_b % 32))**2 + (int(_a / 32) - int(_b / 32))**2));
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

}