pragma solidity ^0.8.35;

contract EpochManager {

    uint constant START_TIME;
    uint constant EPOCH_LENGTH;

    uint CURRENT_GAME_EPOCH = 0;

    constructor(uint epochLength)
    {
        START_TIME = block.timestamp;
        EPOCH_LENGTH = epochLength;
    }

    function computeGameEpoch() returns (uint epoch)
    {
        uint timeDelta = block.timestamp - START_TIME;
        epoch = timeDelta / EPOCH_LENGTH;
        CURRENT_GAME_EPOCH = epoch;
    }

    function computeEpochOf(uint timestamp) pure returns (uint epoch)
    {
        uint timeDelta = timestamp - START_TIME;
        epoch = timeDelta / EPOCH_LENGTH; 
    }
}