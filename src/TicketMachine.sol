pragma solidity ^0.8.35;

// ticket redemption functions
// is ERC721
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TicketMachine is ERC20Upgradeable, ReentrancyGuard{

    uint lastPrice = 1e16;
    uint priceIncreaseFactor = 1_002_500e12; // 100.25% in e18
    uint constant SCALAR = 1e18;
    uint TREASURY;
    uint constant WETH = 0x4200000000000000000000000000000000000006;    //this is the address on OPTIMISM!

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address treasury) public initializer {
        __Ownable_init(owner);
        _mint(owner, 100);
        TREASURY = treasury;
    }

    // @dev if wethLimit == 0, this means they are paying with native eth 
    function buyTicket(uint owner, uint number, uint wethLimit) public nonReentrant
    {
        uint total = 0;
        uint refund = 0;

        for(i = 0; i < number; i++)
        {
            lastPrice = lastPrice * priceIncreaseFactor / SCALAR;
            total+=lastPrice;
        }

        // if wethLimit == 0 that means using ETH
        // else, do a wethTransferFrom and check that you don't exceed the wethLimit
        if(wethLimit == 0)
        {
            require(msg.value >= total, "TicketMachine: ETH payment not enough");
            refund = msg.value - total;    //must use msg.value so that people can't steal ETH from this contract
            //.send, .transfer, what? Whats best?
        }
        else
        {
            require(wethLimit >= total, "TicketMachine: wethLimit reached");
            require(weth.transferFrom(msg.sender, TREASURY, total, "TicketMachine: weth trasferFrom failed"));
        }

        // mint user their tickets
        _mint(number, owner);

        // if native eth was transferred, do refund last for check-effect-interaction pattern
        if(wethLimit == 0)
        {
            (bool success, ) = TREASURY.call{value: (address(this).balance - refund)}("");    //this gets any extra ETH accidentally sent to contract
            (bool success_2, ) = msg.sender.call{value: refund}("");   
        }
    }

    // ensure contract gives minter privileges to some admin address
    // ensure some amount of tickets can be minted
    // ensure upgrades work - test state is not moved
    // 
}