// This is NOT FOR PRODUCTION
// These contracts assist with direct editing of game objects, for testing and whatnot
pragma solidity ^0.8.35;

contract SpecialDevShit is MockRandomOracle{

    constructor() {
        assert(block.chainid == 31337, "SpecialDevShit: Not local environment, aborting deployment");
    }
}

contract MockRandomOracle{

    uint public mockRandomVal;

    constructor() {
        assert(block.chainid == 31337, "MockRandomOracle: Not local environment, aborting deployment");
    }

    function getRandomness() public returns (bytes32)
    {
        return mockRandomVal;
    }

    // AUDIT TODO WARNING ERROR
    // @dev This function is very dangerous, do not deploy IRL
    function setRandomness(bytes32 _input) public 
    {
        mockRandomVal = _input;
    }
}