pragma solidity ^0.8.35;

import "./QueueDispatcher.sol";
import "./QueueStorage.sol";
import "./TimedEvents.sol";
import "./RandomEvents.sol";
import "./UserActions.sol";
import "./Updater.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract QueueProcessor is QueueDispatcher, QueueStorage, TimedEvents, RandomEvents, UserActions, Updater, OwnableUpgradeable {
    
    enum QueueStatus {
        NOT_READY,  //not enough time has passed to start this
        READY,      //ready to get staged, but all others must be processed first     
        STAGED,     // staged! awaiting random seed generation
        SEEDED,     // random seeded
        PARTIAL,    //processed partially
        COMPLETED   //completely processed
    }

    mapping(uint => QueueStatus) queueStatuses;

    uint public currentlyStaged;
    uint public stagedTime;
    uint public currentSeed;    //TODO: Consider changing to SEED because its a global var
    uint public partialProgress;
    uint public lastStaged; // we can call non-existent queues "staged"

    constructor(address _randOracle)
    {
        RAND_ORACLE = _randOracle;
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

        _doTerrainUpdates(worldId);
        _doWorldUpdates(worldId);

        //ensure that enough time has passed for sufficient randomness when pulling random oracle
        // 1. get world
        // 2. locate affected spots (64 of them)
        // 3. update
        // 4. do world updates
        // Reminder to self - this is a fine first draft


    }

    function _rollSeed() internal returns(bytes32)
    {
        return currentSeed = keccak(currentSeed);
    }

    // Why did i call it spice? Idk. Loosen up, mannn
    function _getSpice() internal view returns(bytes32)
    {
        return IRandomOracle(RAND_ORACLE).getRandomness();
    }

    function applyRandomness() external returns(bytes32)
    {
        return currentSeed = keccak(abi.encode(currentSeed, _getSpice()));

    }




    function _isNextQueue(queueId) public returns(bool)
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
    function _doTerrainUpdates(worldId) internal returns(mapping(uint => bool) updated)
    {

        for(i =  0; i < NUM_WORLD_UPDATES; i++)
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

    function _updateSpace(uint worldId,uint x, uint y)
    {
        _rollSeed();

        // get type 
        // update by type
        uint spaceType = _getType(x,y,worldId);
        
        /*
        switch spaceType
        {
            case(TE_PLANT):
            case(TE_WATER):
            case(TE_ROCKS):
        }
        */  //TODO fill this out and chang away from switch case

    }

}