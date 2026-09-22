pragma solidity ^0.8.35;

contract QueueStorage{

    // each epoch has its own queue and we separate those
    // TODO why do we do this again? This needs to be documented
    mapping(uint => uint) public queueLengths;

    mapping(uint worldId => uint) public nextQueueEpoch;    

    struct Queue{
        uint queueProcessTime;
    }

    mapping(uint epochNumber => mapping(uint queuePosition => uint)) queues;
    mapping(uint worldId => uint epoch) lastUpdate;


}