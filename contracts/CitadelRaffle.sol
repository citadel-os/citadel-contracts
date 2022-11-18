pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CitadelRaffle is Ownable {
    uint256 public MIN = 0;
    uint256 public MAX = 0;

    constructor() {
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, MIN, MAX)));
    }

    function updateParameters(uint256 _min, uint256 _max) public onlyOwner {
        MIN = _min;
        MAX = _max;
    }

    function raffle() public view onlyOwner returns(uint256) {
        uint256 _random = random();
        uint256 winner = (_random % (MAX - MIN + 1)) + MIN;

        return winner;
    }
}