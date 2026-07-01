pragma solidity ^0.8.35;

// ticket redemption functions
// is ERC721
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IWETH9.sol";

contract TicketMachine is ERC20BurnableUpgradeable, ReentrancyGuard, OwnableUpgradeable{

    uint public lastPrice;
    uint priceIncreaseFactor; 
    uint constant SCALAR = 1e18;
    address TREASURY;
    IWETH9 weth;    //this is the address on OPTIMISM!
    uint maxPrice;
    uint numOwnerMints;
    uint maxOwnerMints;

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address treasury) public initializer {
        __Ownable_init(owner);
        __ERC20_init("LandNFT Tickets", "TICKET");
        TREASURY = treasury;
    
        lastPrice = 1e16;
        priceIncreaseFactor = 1_002_500e12; // 100.25% in e18
        weth =  IWETH9(0x4200000000000000000000000000000000000006);
        maxPrice = 0.1 ether;
        maxOwnerMints = 1000;
    }

    function getPrice() public view returns(uint price)
    {
        uint thisPrice = lastPrice * priceIncreaseFactor / SCALAR;
        if(thisPrice > maxPrice) { thisPrice = maxPrice; }
        return thisPrice;
    }

    // @dev if wethLimit == 0, this means they are paying with native eth 
    function buyTicket(address recipient, uint number, uint wethLimit) public payable nonReentrant
    {
        uint total = 0;
        uint refund = 0;

        for(uint i = 0; i < number; i++)
        {
            uint thisPrice = lastPrice * priceIncreaseFactor / SCALAR;

            if(thisPrice > maxPrice)
            {
                thisPrice = maxPrice;
            }

            total+=thisPrice;
            lastPrice = thisPrice;
        }

        // if wethLimit == 0 that means using ETH
        // else, do a wethTransferFrom and check that you don't exceed the wethLimit
        if(wethLimit == 0)
        {
            require(msg.value >= total, "TicketMachine: ETH payment not enough");
            refund = msg.value - total;    //must use msg.value so that people can't steal ETH from this contract
        }
        else
        {
            require(wethLimit >= total, "TicketMachine: wethLimit reached");
            require(weth.transferFrom(msg.sender, TREASURY, total), "TicketMachine: weth trasferFrom failed");
        }

        // mint user their tickets
        _mint(recipient, number);

        // if native eth was transferred, convert to weth and send to treasury.
        // since weth payable amount is determined when tx sent, refund unused funds to the user
        // do refund last for check-effect-interaction pattern
        if(wethLimit == 0)
        {        
            uint thisAmount = address(this).balance - refund;   // this gets any stray ETH in the contract as well
            weth.deposit{value: thisAmount}(); //deposit into the WETH contract    
            weth.transfer(TREASURY, thisAmount);

            (bool success, ) = msg.sender.call{value: refund}("");   
            require(success, "TicketMachine: failure in transferring refund");
        }
    }

    // TODO add tests for this
        // make sure it works
        // make sure it fails after the max number of mints fails
    function ownerMint(uint number) public onlyOwner
    {
        require(numOwnerMints + number <= maxOwnerMints, "TicketMachine: max owner mints exceeded");
        _mint(owner(), number);
        numOwnerMints += number;
    }
}