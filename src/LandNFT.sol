pragma solidity ^0.8.35;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "./TicketMachine.sol";
import "./EpochManager.sol";
import "./QueueProcessor.sol";

contract LandNFT is 
    Initializable, 
    ERC721EnumerableUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuard,
    EpochManager,
    QueueProcessor {

    ERC20BurnableUpgradeable ticketMachine;

    mapping(uint tokenId => mapping(address processor => bool)) canProcess;

    constructor() {
        _disableInitializers();     //Implementation should not be allowed to initialize
    }

    // TODO: make sure initializer flow is good. Double check how it works
    function initialize(address owner, address _ticketMachine) public initializer {
        __Ownable_init(owner);
        ticketMachine = ERC20BurnableUpgradeable(_ticketMachine);
    }

    function version() public pure returns(string memory) {
        return "1.0.0";
    }


    function redeemTicket(uint numTickets) public nonReentrant{
        for(uint i = 0; i < numTickets; i++)
        {
            ticketMachine.transferFrom(msg.sender,address(this),1);
            ticketMachine.burn(1);
                // TODO AUDIT ensure reverts when transferFrom fails - can also burn ticket to confirm
            // TODO AUDIT is there any way to mint the same identifier more than once?
            // TODO AUDIT is there any way to re-enter this function upon minting? If so, what can we do to stop that?
            
            // get current number of NFTs in existence, then mint the next id
            // Always doing this means we always mint the next id in order //TODO AUDIT right??
                // may need mint consecutive
            _mint(msg.sender, totalSupply());   // Calls ERC721Upgradeable._mint()
                //TODO AUDIT - this is not off-by-one right?    
                //TODO AUDIT: consider using safemint
        }
    }

    /** 
     * @dev Updates an island `numEpochs` number of cycles. 
     * @dev Will stop early if the island is caught up to the current global epoch
     * @dev Each epoch, random events occur, then chance-timed occurences (eg plant growth), then timed occurrences, then queued user actions if possible 
     */
    function processEpochs(uint tokenId, uint numEpochs) public nonReentrant{
        require(_canProcess(tokenId, msg.sender), "processEpochs: msg.sender cannot process for this tokenId");
        _attemptUpdateToEpoch(tokenId, worlds[tokenId].lastUpdatedEpoch + numEpochs);
    } 

    function processUpToEpoch(uint tokenId, uint finalEpoch) public nonReentrant {
        require(_canProcess(tokenId, msg.sender), "processUpToEpoch: msg.sender cannot process for this tokenId");
        _attemptUpdateToEpoch(tokenId, finalEpoch);
    }

    //TODO is this for user actions only? If so, consider updating the name here to "queueUserAction"
    function queueAction(uint tokenId, uint action, bytes32 aux) public //TODO nonreentrant?
    {
        require(_canQueueActions(tokenId, msg.sender), "queueAction: msg.sender cannot queue actions for this tokenId");
        return _queueActionInEpoch(tokenId, action, worlds[tokenId].lastUpdatedEpoch + 1);
    }

    // TODO Are there any other "actions"? If so, consider calling this "queueUserActionInEpoch".
    //      Otherwise make it clear that "action" is a reserved word for user actions
    function queueActionInEpoch(uint tokenId, uint action, bytes32 aux, uint epoch) public  //TODO nonreentrant?
    {
        require(_canQueueActions(tokenId, msg.sender), "queueActionInEpoch: msg.sender cannot queue actions for this tokenId");
        require(epoch > worlds[tokenId].lastUpdatedEpoch, "queueActionInEpoch: specified epoch has already passed");  
        return _queueActionInEpoch(tokenId, action, epoch);
    }

    function _attemptUpdateToEpoch(uint tokenId, uint finalEpoch) internal
    {


        for(uint i = worlds[tokenId].lastUpdatedEpoch + 1; i <= finalEpoch; i++)
        {
            // this is for the very end of the update round, all changes to be made due to rolls and such
            Effect[] effects = new Effect[];
            
            // do random events
            // do chanceTimed occurrences
            Event[] timedEvents = _scanForTimedEvents(tokenId);

            Effect[] effectsFromTimed = new Effect[];
            effectsFromTimed = _doTimedEvents(timedEvents);
            // do timed occurrences (things like decay or non-infinite effects... tbh this might be ok to remove)
            // do queued user actions

            // TODO: might need to setup a "router" scheme for NFTs from different versions
            //      This would mean all NFTs are stored here, WITH THIER VERSIONS, and the router would determine which 
            //      QueueProcessor to call


        }
    }

    function _queueActionInEpoch(uint tokenId, uint action, uint epoch) internal
    {
        // TODO fill this out - what checks can we assume have already been done?
    }

    function _canQueueActions(uint tokenId, address caller)
    {
        require(caller == ownerOf(tokenId), "LandNFT:_canQueueActions - caller is not NFT owner");  //TODO change this to use allowances?
    }

    // TODO: if we keep this structure, this may be one-lineable instead of calling _canProcess each time. Tho maybe thats cleaner. Considerate
    function _canProcess(uint tokenId, address caller)
    {
        require(canProcess[tokenId][caller], "LandNFT:_canProcess - caller cannot process");
    }
    // TODO: create a token permissions contract for all this stuff. Can queue, can process, etc
    


}