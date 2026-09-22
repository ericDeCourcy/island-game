pragma solidity ^0.8.35;

import "./QueueProcessor.sol";

contract WorldState {
    
    // state of player worlds
    struct World{
        uint[32][32] terrain;
        mapping(uint => uint) entities;
        uint numEntities;
        bool exists;
    }

    struct Entity{  //TODO what are entities? How do we handle entities which inhabit worlds?
        uint id;
        uint entityType;
        bool onWorld;   //TODO: what does this mean? 
        uint location;  
        mapping(uint => uint) status;   //TODO: What are statuses? why are there multiple statuses?
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