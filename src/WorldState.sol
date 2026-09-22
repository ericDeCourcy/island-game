pragma solidity ^0.8.35;

import "./QueueProcessor.sol";

contract WorldState {
    
    // state of player worlds
    struct World{
        uint[32][32] terrain;
        mapping(uint => uint) entities;
        mapping(uint x => mapping(uint y => uint)) objects; //plants, items, etc
        uint numEntities;
        bool exists;
        uint creationEpoch;
        uint lastUpdatedEpoch;
    }

    struct Entity{  //TODO what are entities? How do we handle entities which inhabit worlds?
        uint id;
        uint entityType;
        bool onWorld;   //TODO: what does this mean? 
        uint location;  
        mapping(uint => uint) status;   //TODO: What are statuses? why are there multiple statuses?
    }

    struct Effect{  //TODO minimize type sizes because we process lots of these
        uint8 x;
        uint8 y;
        uint val;
        uint tileType;
        uint eventType;
        uint eventUid;
        uint tokenId;    //TODO should this just be id? what is this used for?
    }

    mapping(uint => World) public worlds;
    uint public numWorlds;

    mapping(uint => Entity) public entities;
    uint public numEntities;

    

    modifier onlyIfWorldExists(uint worldId) 
    {
        require(worldExists(worldId), "WorldState:onlyIfWorldExists - World does not exist");
    }

    function getTerrainElement(uint worldId, uint x, uint y) external view returns (uint) {
        require(worlds[worldId].exists, "WorldState: worldId does not exist");
        return worlds[worldId].terrain[x][y];
    }

    function getEntity(uint id) external view returns (uint) {
        return entities[id];
    }

    function getNumEntities(uint worldId) external view returns (uint) {
        return worlds[worldId].numEntities;
    }

    function getEntityStatus(uint entityId, uint statusId) external view returns(uint) {
        return entities[entityId].status[statusId];
    }

    function worldExists(uint worldId) public view returns(bool) {
        return worlds[worldId].exists;
    }



}