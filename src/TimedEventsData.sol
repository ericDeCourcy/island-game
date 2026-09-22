pragma solidity ^0.8.35;

// This file is dedicated to lookup tables for various chances

contract TimedEventsData {


    // Each timed event has an array of these, to allow for some events having a greater chance as time goes on
    struct ChancesElement {
        uint age; //measured in epochs, since the action was created
        uint probability; //measured as "some hash must be greater than this"
    }

    // TODO make sure this is getting called whenever the contract initializes
    function initChances() // TODO incorporate `initializer`  9/21
    {

    }

    // TODO: this needs fixed, i don't like the idea of chances being spread out across 32 bytes
    // TODO: right now this just returns 50% for everything
    function getChances(uint, uint) returns (bytes32)
    {
        return bytes32(uint.max()/2);
    }
}