contract WorldState {
    
    // state of player worlds
    struct World{
        uint[32][32] terrain;
        mapping(uint => uint) entities;
        uint numEntities;
        bool exists;
    }

    struct Entity{
        uint id;
        uint entityType;
        bool onWorld;
        uint location;  
        mapping(uint => uint) status;
    }


    public mapping(uint => World) worlds;
    public uint numWorlds;

    public mapping(uint => Entity) entities;
    public uint numEntities;

    function getTerrainElement(uint worldId, uint x, uint y) external view returns (uint) {
        require(worlds[worldId].exists, "WorldState: worldId does not exist");
        return worlds[worldId].terrain[x][y];
    }

    function getEntity(uint id) external view returns (uint) {
        return world.entities[id];
    }

    function getNumEntities() external view returns (uint) {
        return world.numEntities;
    }

    function getEntityStatus(uint entityId, uint statusId) external view returns(uint) {
        return entities[entityId].status[statusId];
    }



}