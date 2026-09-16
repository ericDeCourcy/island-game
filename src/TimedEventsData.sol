// This file is dedicated to lookup tables for various chances

contract TimedEventsData {


    // Each timed event has an array of these, to allow for some events having a greater chance as time goes on
    struct ChancesElement {
        uint age; //measured in epochs, since the action was created
        uint probability; //measured as "some hash must be greater than this"
    }

    // TODO make sure this is getting called whenever the contract initializes
    function initChances() initializer 
    {

    }
}