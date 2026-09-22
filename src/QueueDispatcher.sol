pragma solidity ^0.8.35;

import "./WorldState.sol";
import "./QueueStorage.sol";

// TODO better name than "dispatcher"? What does this do?
contract QueueDispatcher is WorldState, QueueStorage {  

    uint immutable MAX_QUEUE_LENGTH;
    uint immutable QUEUE_PERIOD;
    uint immutable FIRST_QUEUE_TIME;
    uint immutable QUEUE_ADD_DELAY;

    event QueueDispatcherConstructed(uint maxQueueLength, uint queuePeriod, uint firstQueueTime, uint queueAddDelay);

    constructor(uint _maxQueueLength, uint _queuePeriod, uint _firstQueueTime, uint _queueAddDelay)
    {
        MAX_QUEUE_LENGTH = _maxQueueLength;
        QUEUE_PERIOD = _queuePeriod;
        FIRST_QUEUE_TIME = _firstQueueTime;
        QUEUE_ADD_DELAY = _queueAddDelay;

        emit QueueDispatcherConstructed(MAX_QUEUE_LENGTH, QUEUE_PERIOD, FIRST_QUEUE_TIME, QUEUE_ADD_DELAY);
    }

    function addToQueue(uint worldId) public onlyIfWorldExists(worldId) returns(uint batch) //returns 0 if not added to a batch at all
    {
        require(block.timestamp - lastUpdate[worldId] > QUEUE_ADD_DELAY, "QueueDispatcher: World cannot be added to queue yet");    //TODO: 9/21/26 whats this... what does this prevent?
        require(_inQueue(worldId) == 0, "QueueDispatcher: World is already in a queue");    //TODO: change default val for "not in queue" to uint(max)
        _addToCurrentQueue(worldId);
    }

    // proves the queue doesn't exist so we can't get stuck waiting for it
    // TODO: what does this mean?
    //  9-16-26 i guess maybe this could mean that the epoch hasn't happened yet. Probably 
    function proveQueueDNE(uint queueId) public returns(bool DNE)
    {
        // 9-16-26 commenting out for now...
        //if(block.timestamp / QUEUE_EPOCH );
        return ((block.timestamp -FIRST_QUEUE_TIME) / QUEUE_PERIOD < queueId);
        // alternatively if this is just needed to prevent out of order it could just return the last queue completed...? idk
        // what queues even are
        // TODO fix help aaa
    }


    // For addToQueue //////////////
    function _inQueue(uint worldId) returns (uint queueNumber)
    {
        return nextQueueEpoch[worldId];  // if nextQueue is zero then that means world isn't in queue
            // TODO: change the default val for "not in queue" to be uint(max)
    }


    //
    function _addToCurrentQueue(uint worldId) returns (bool success, uint queueNumber)
    {
        uint currentQueue = (block.timestamp - FIRST_QUEUE_TIME) / QUEUE_PERIOD;
        uint currentlength = queueLengths[currentQueue];
        require(currentlength < MAX_QUEUE_LENGTH, "QueueDispatcher: Cannot exceed max queue length");
        queues[currentQueue][currentlength];
        queueLengths[currentQueue]++; 
    }
    //////////////////////////////



}