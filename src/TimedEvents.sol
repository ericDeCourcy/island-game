pragma solidity ^0.8.35;

import "./TimedEventsData.sol";
import "./WorldState.sol";
import "./RandomnessManager.sol";

// Timed events are things like plants growing and shit
contract TimedEvents is TimedEventsData, WorldState, RandomnessManager {
// timed events are special, because for some events there are bell curves that need to be dealt with and sometimes things are strictly linear
// TODO what does this mean? 9/19/26



    struct Event {
        uint eventType; 
        uint eventUid;
        uint x;     //x coordinate on island, optional
        uint y;     //y coordinate on island, optional
        uint initEpoch;  //epoch this event spawned in
        uint tokenId;
    }

    // Stores a finite array indicating odds as a stairstep function. Note that these are the odds per epoch
    // Probability(numEpochs) =  1 - (1 - chances)^numEpochs
    mapping(uint timedEvent => ChancesElement[]) Chances;

    mapping(uint tokenId => Event[]) TerrainEventsCache;    //This is a cache so that we don't have to scan every square of an island
                                                            // we can do away with this in favor of more efficient processing as things evolve. 
                                                            // Do not use this structure outside of TimedEvents to prevent it from becoming load bearing

    uint EVENT_UID_COUNTER = 0; //can never decrease, gets incremented every time a new event is added


    // Scans a tokenId's world map (and potentially other sources) to create a list of timed events to execute
    function _scanForTimedEvents(uint tokenId) internal returns(Event[])
    {
        return _getTerrainEvents(tokenId); 
    }

    // returns the terrain related timed events that occur
    function _getTerrainEvents(uint tokenId) internal returns(Event[])
    {
        return TerrainEvents[tokenId];
    }

    // @dev Needs `initEpoch` specified because these are per-token and may not correspond to the current game latest epoch
    // TODO consider adding an "old event uid" thing for events. But then i think nah, just delete old ones as you create new ones if necessary
    function _addTerrainEvent(uint tokenId, uint eventType, uint x, uint y, uint initEpoch) internal returns(uint index)
    {
        Event thisEvent = new Event;
        thisEvent.eventType = eventType;
        thisEvent.x = x;
        thisEvent.y = y;
        thisEvent.initEpoch = initEpoch; 
        thisEvent.eventUid = EVENT_UID_COUNTER++;
        thisEvent.tokenId = tokenId;

        // TODO: consider adding reverse-lookup eventUid --> tokenId
        TerrainEvents[tokenId].push(thisEvent); //Adds event to the list
        emit TerrainEventAdded(tokenId, thisEvent.eventUid);
    } 

    function _doTimedEvents(Event[] events)
    {
        Effect[] timedEventEffects = new Effect[];


        for(i = 0; i < events.length; i++)
        {
            bool happened = _eventRoll(events[i].eventType, events[i].initEpoch);
            if(happened)
            {
               timedEventEffects.push( _processEvent(events[i]));
            }
        }

        return timedEventEffects;
    }

    function _eventRoll(uint eventType, uint initEpoch) returns (bool)
    {
        return rollRand() < getChances(eventType, tokenEpoch - initEpoch);
    }

    function _processEvent(Event thisEvent) internal returns (Effect[] effects)
    {
        if(thisEvent.eventType == TimedEvent.REDPLANT_GROWTH)
        {
            // get x,y of the event, find redplant stage, then update redplant to the next stage
            // note: there are 7 redplant stages
                // create effect of "change tile to X"
            // if redplant has reached the final stage, then add effect of changing this tile to redp
                // create effect of "remove terrain event" and "add terrain event" for redplant fruit start
            
            // TODO AUDIT: consider making a getter for the tile type
            if(worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y] >= TileType.REDPLANT_0 && worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y] < TileType.REDPLANT_6) // This does NOT include REPLANT_6
            {
                Effect setNextTile = new Effect;
                setNextTile.tileType = EffectTileType.SET_TILE;
                setNextTile.x = thisEvent.x;
                setNextTile.y = thisEvent.y;
                setNextTile.val = worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y]+1;

                effects.push(setNextTile);
            }
            else if(worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y] == TileType.REDPLANT_6)
            {
                Effect setNextTile = new Effect;
                setNextTile.tileType = EffectTileType.SET_TILE;
                setNextTile.x = thisEvent.x;
                setNextTile.y = thisEvent.y;
                setNextTile.val = TileType.REDPLANT_FRUIT_0;

                Effect deleteOldEvent = new Effect;
                deleteOldEvent.eventType = EffectEventType.DEL_EVENT;
                deleteOldEvent.eventUid = thisEvent.eventUid;

                Effect createNewEvent = new Effect; //TODO need better name than "event", perhaps something like roll or smth
                createNewEvent.eventType = EffectEventType.NEW_EVENT;
                createNewEvent.x = thisEvent.x;
                createNewEvent.y = thisEvent.y;
                createNewEvent.tokenId = thisEvent.tokenId;
                createNewEvent.val = TimedEvent.REDPLANT_FRUIT_START;

                effects.push(setNextTile);
                effects.push(deleteOldEvent);
                effects.push(createNewEvent);
            }
            else
            {
                revert("_processEvent: impossible tile type for event");
            }


        }
        else if(thisEvent.eventType == TimedEvent.REDPLANT_FRUIT_START)
        {
            // get x,y of event, then update redplant to next stage
                // create effect of change tile to redplant-fruit-stage++
            // if redplant fruit
            uint tileType = _getTileType(thisEvent);
            
            require(tileType == TileType.REDPLANT_FRUIT_0, "_processEvent: Event/tile mismatch: REDPLANT_FRUIT_START");

            Effect setNextTile = new Effect;
            setNextTile.tileType = EffectTileType.SET_TILE;
            setNextTile.x = thisEvent.x;
            setNextTile.y = thisEvent.y;
            setNextTile.val = TileType.REDPLANT_FRUIT_1;

            Effect deleteOldEvent = new Effect;
            deleteOldEvent.eventType = EffectEventType.DEL_EVENT;
            deleteOldEvent.eventUid = thisEvent.eventUid;

            Effect createNewEvent = new Effect; //TODO need better name than "event", perhaps something like roll or smth
            createNewEvent.eventType = EffectEventType.NEW_EVENT;
            createNewEvent.x = thisEvent.x;
            createNewEvent.y = thisEvent.y;
            createNewEvent.tokenId = thisEvent.tokenId;
            createNewEvent.val = TimedEvent.REDPLANT_FRUIT_GROWTH;

            effects.push(setNextTile);
            effects.push(deleteOldEvent);
            effects.push(createNewEvent);
        }
        else if(thisEvent.eventType == TimedEvent.REDPLANT_FRUIT_GROWTH)
        {

            Effect setNextTile = new Effect;
            setNextTile.tileType = EffectTileType.SET_TILE;
            setNextTile.x = thisEvent.x;
            setNextTile.y = thisEvent.y;
            setNextTile.val = worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y] + 1;

            // don't create new event, event is same or deleted
 

            effects.push(setNextTile);
            if(worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y] == TileType.REDPLANT_FRUIT_11)
            {
                Effect deleteOldEvent = new Effect;
                deleteOldEvent.eventType = EffectEventType.DEL_EVENT;
                deleteOldEvent.eventUid = thisEvent.eventUid;
                effects.push(deleteOldEvent);
            }
        }
        else revert("thisEvent.eventType does not exist");

    }


    function _getTileType(Event thisEvent) returns (uint tileType) 
    {
        return worlds[thisEvent.tokenId].objects[thisEvent.x][thisEvent.y];
    }
}