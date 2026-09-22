pragma solidity ^0.8.35;

import "./WorldState.sol";

contract QueueStorage is WorldState {

    // each epoch has its own queue and we separate those
    // TODO why do we do this again? This needs to be documented
    mapping(uint => uint) public queueLengths;

    mapping(uint worldId => uint) public nextQueueEpoch;    

    struct Queue{
        uint queueProcessTime;
    }

    struct Event {  // TODO: Move to base contract called "SystemStructs" or something
        uint eventType; 
        uint eventUid;
        uint x;     //x coordinate on island, optional
        uint y;     //y coordinate on island, optional
        uint initEpoch;  //epoch this event spawned in
        uint tokenId;
    }

    mapping(uint epochNumber => mapping(uint queuePosition => uint)) queues;
    mapping(uint worldId => uint epoch) lastUpdate;

    mapping(uint worldId => Event[]) TerrainEvents;


}