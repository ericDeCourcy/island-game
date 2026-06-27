contract QueueDispatcher {

    function addToQueue(uint worldId) public worldExists(worldId) returns(uint batch) //returns 0 if not added to a batch at all
    {
        require(block.timestamp - lastUpdate[worldId] > QUEUE_ADD_DELAY, "QueueDispatcher: World cannot be added to queue yet");
        require(_inQueue(worldId) == 0, "QueueDispatcher: World is already in a queue");
        _addToCurrentQueue(worldId);
    }

    // proves the queue doesn't exist so we can't get stuck waiting for it
    function proveQueueDNE(uint queueId) public returns(bool DNE)
    {
        if(block.timestamp / QUEUE_EPOCH )
    }


    // For addToQueue //////////////
    function _inQueue(uint worldId) returns (uint queueNumber)
    {
        return queueStatus[worldId];
    }
    //
    function _addToCurrentQueue(uint worldId) returns (bool success, uint queueNumber)
    {
        currentQueue = block.timestamp / QUEUE_EPOCH;
        currentlength = queueLengths[currentQueue];
        require(currentlength < MAX_QUEUE_LENGTH, "QueueDispatcher: Cannot exceed max queue length");
        queues[currentQueue][currentlength];
        queueLengths++; 
    }
    //////////////////////////////



}