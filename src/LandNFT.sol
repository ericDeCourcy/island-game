pragma solidity ^0.8.35;

// ticket redemption functions
// is ERC721
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TicketMachine.sol";

contract LandNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable{

    constructor() {
        _disableInitializers();     //Implementation should not be allowed to initialize
    }

    // TODO: make sure initializer flow is good. Double check how it works
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    function version() public pure returns(string memory) {
        return "1.0.0";
    }


    function redeemTicket(uint numTickets) public {
        TicketMachine.transferFrom(msg.sender,address(this),1);
            // TODO ensure reverts when transferFrom fails 
        _mint(msg.sender);
    }



}