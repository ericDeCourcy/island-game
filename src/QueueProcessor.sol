pragma solidity ^0.8.35;

import "./QueueDispatcher.sol";
import "./TimedEvents.sol";
import "./RandomEvents.sol";
import "./UserActions.sol";
import "./Updater.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract QueueProcessor is QueueDispatcher, TimedEvents, RandomEvents, UserActions, Updater, OwnableUpgradeable {
    
    enum QueueStatus {
        NOT_READY,  //not enough time has passed to start this
        READY,      //ready to get staged, but all others must be processed first     
        STAGED,     // staged! awaiting random seed generation
        SEEDED,     // random seeded
        PARTIAL,    //processed partially
        COMPLETED   //completely processed
    }

    mapping(uint => QueueStatus) queueStatuses;

    uint immutable NUM_WORLD_UPDATES;

    uint public currentlyStaged;
    uint public stagedTime;
    uint public currentSeed;    //TODO: Consider changing to SEED because its a global var
    uint public partialProgress;
    uint public lastStaged; // we can call non-existent queues "staged"
    
    event QueueStaged(uint indexed queueId);

    constructor(address _randOracle, uint _numWorldUpdates)
    {
        RAND_ORACLE = _randOracle;
        NUM_WORLD_UPDATES = _numWorldUpdates;
    }

    // TODO: make it possible to process fixed number of queues?
    function stageQueue(uint queueId) public returns(bool success)
    {
        require(block.timestamp > queues[queueId].queueProcessTime);
        bool canStage = _isNextQueue(queueId);
        if(canStage)
        {
            currentlyStaged = queueId;
            lastStaged = queueId;
            partialProgress= 0;
            stagedTime = block.timestamp;
            emit QueueStaged(queueId);
            return true;
        }
        return false;
    }

    function processQueue(uint number)
    {
        // get partial progress

        // check is not more than length of queue

        // do that one

        // TODO: Get worldId from the queue somehow
        // _doTerrainUpdates(worldId);
  
  
        //  _doWorldUpdates(worldId); //TODO: diff between terrain and world updates?

        //ensure that enough time has passed for sufficient randomness when pulling random oracle
        // 1. get world
        // 2. locate affected spots (64 of them)
        // 3. update
        // 4. do world updates
        // Reminder to self - this is a fine first draft


    }



    function _isNextQueue(uint queueId) public returns(bool)
    {
        // if anything staged now, abort
        if(currentlyStaged != 0)
        {
            return false;
        }

        // if nothing staged, while queue does not exist, increment "last processed" and continue
        if(queueId > lastStaged + 1)
        {
            uint checkpointQueue = lastStaged+1;
            while(proveQueueDNE(checkpointQueue))   //skip over all queues which don't exist, plus checkpointing for queueId
            {
                checkpointQueue++;
                lastStaged++;
            }

            if(checkpointQueue != queueId)
            {
                return false;
            }
        }

        if(queueId == lastStaged + 1)
        {
            return true;
        }

        return false;

    }


    // Terrain updates are occasional changes to the landscape that can just happen sometimes. 
    // They are not the same as Timed Events, which happen after some delay for something
    // like plant growth.
    // TODO: Consider returning an array instead of a mapping, i'm not sure how mapping returns work 9/21
    function _doTerrainUpdates(uint worldId) internal returns(mapping(uint => bool) updated)
    {

        for(uint i =  0; i < NUM_WORLD_UPDATES; i++)
        {

            _rollSeed();
            uint x = uint(currentSeed) % 32;
            uint y = (uint(currentSeed) / 32)%32;

            if(updated[x + (y*32)])
            {
                i--;    //this is okay cuz its impossible to have this happen on zero causing underflow
            }
            else
            {
                updated[x + (y*32)] = true;
                _updateSpace(worldId,x,y);
            }
        }
    }

    // For a given space, this will perform an "update" to said space based on what it is
    // Not every space gets updated every epoch, so this is a random chance
    // TODO where do the random chance rolls occur? Don't we want to use the "chances" setup we already have?
    function _updateSpace(uint worldId,uint x, uint y) internal
    {
        _rollSeed();

        // get type 
        // update by type
        uint spaceType = _getType(worldId, x,y);


        
        /*
        switch spaceType
        {
            case(TE_PLANT):
            case(TE_WATER):
            case(TE_ROCKS):
        }
        */  //TODO fill this out and change away from switch case

    }

    function _getType(uint worldId, uint x, uint y)
    {
        return worlds[worldId].terrain[x][y];
    }

}