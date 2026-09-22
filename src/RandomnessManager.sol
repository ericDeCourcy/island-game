pragma solidity ^0.8.35;

contract RandomnessManager {

    function rollRand() internal returns(bytes32)
    {
        return _rollSeed(); 
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

    // incorporates current random oracle reading into seed
    function applySpice() external returns(bytes32)
    {
        return currentSeed = keccak(abi.encode(currentSeed, _getSpice()));
        //TODO: make it applicable exactly once per update/block
    }

    function applySalt(bytes32 _userSalt) external returns(bytes32)
    {
        // TODO: this is user-supplied
        //  Current plan for this is to use a "random" pile where some user's salt gets grabbed (which salt is based on the current random value)
        //  then this gets "used up" and incorporated into the seed, and replaced by the current caller's added salt 
        //  Once queue is big enough size, salts get applied
        //  Salts must be aged since they are user supplied. Consider adding an "added in epoch" val to each salt.
    }
}

