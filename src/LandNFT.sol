pragma solidity ^0.8.35;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "./TicketMachine.sol";

contract LandNFT is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuard{

    ERC20BurnableUpgradeable ticketMachine;

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
            _mint(msg.sender, totalSupply());   //TODO AUDIT - this is not off-by-one right?
        }
    }



}