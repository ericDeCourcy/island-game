// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "../src/TicketMachine.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TicketMachineTest is Test {
    TicketMachine public implementation;
    TicketMachine public ticketMachine;
    ERC1967Proxy public proxy;

// TODO AUDIT - note that these addresses are non-eoas and so transfers from the WETH contract may fail
    address owner    = makeAddr("owner");
    address treasury = makeAddr("treasury");
    address user     = makeAddr("user");

    IWETH9 weth = IWETH9(0x4200000000000000000000000000000000000006);

    string OPTIMISM_RPC = vm.envString("OPTIMISM_RPC_URL");

    function setUp() public {
        vm.createSelectFork(OPTIMISM_RPC);

        // deploy implementation
        implementation = new TicketMachine();

        // deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            TicketMachine.initialize.selector,
            owner,
            treasury
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        ticketMachine = TicketMachine(address(proxy));
    }

    // --- deployment checks ---

    function test_deployment_nameAndSymbol() public view {
        assertEq(ticketMachine.name(),   "LandNFT Tickets");
        assertEq(ticketMachine.symbol(), "TICKET");
    }

// TODO: consider removing this. Originally 100 tickets were minted to the owner, now its 0
    function test_deployment_ownerReceivesInitialTickets() public view {
        assertEq(ticketMachine.balanceOf(owner), 0);
    }

    function test_deployment_ownerIsSet() public view {
        assertEq(ticketMachine.owner(), owner);
    }

    function test_deployment_totalSupply() public view {
        assertEq(ticketMachine.totalSupply(), 0);
    }

    function test_deployment_implementationInitializersDisabled() public {
        // calling initialize on the bare implementation should revert
        vm.expectRevert();
        implementation.initialize(owner, treasury);
    }

    function test_deployment_wethAddressIsLive() public view {
        // confirm the hardcoded WETH address has code on the Optimism fork
        assertGt(address(weth).code.length, 0);
    }

    // --- buy ticket (ETH path) ---

    function test_buyTicket_ethPath_mintsTickets() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        ticketMachine.buyTicket{value: 0.1 ether}(user, 1, 0);

        assertEq(ticketMachine.balanceOf(user), 1);
    }

    function test_buyTicket_ethPath_treasuryReceivesWeth() public {
        vm.deal(user, 1 ether);
        uint256 before = weth.balanceOf(treasury);

        vm.prank(user);
        ticketMachine.buyTicket{value: 0.1 ether}(user, 1, 0);

        assertGt(weth.balanceOf(treasury), before);
    }

    function test_buyTicket_ethPath_revertsIfUnderpaid() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert("TicketMachine: ETH payment not enough");
        ticketMachine.buyTicket{value: 1 wei}(user, 1, 0);
    }

    // --- buy ticket (WETH path) ---

    function test_buyTicket_wethPath_mintsTickets() public {
        uint256 price = 1e17; // should be enough for the ticket

        // fund user with WETH
        vm.deal(user, price);
        vm.prank(user);
        weth.deposit{value: price}();

        vm.prank(user);
        weth.approve(address(ticketMachine), price);

        vm.prank(user);
        ticketMachine.buyTicket(user, 1, price);

        assertEq(ticketMachine.balanceOf(user), 1);
    }

    function test_buyTicket_wethPath_revertsIfLimitTooLow() public {
        vm.prank(user);
        vm.expectRevert("TicketMachine: wethLimit reached");
        ticketMachine.buyTicket(user, 1, 1 wei); // wethLimit way too low
    }

    function test_ownerMint() public {
        vm.prank(owner);
        ticketMachine.ownerMint(10);
        assertEq(ticketMachine.balanceOf(owner), 10);
    }

    function test_ownerMint_fails_nonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        ticketMachine.ownerMint(10);
    }

    function test_ownerMint_failsWhenExceeding() public {
        vm.prank(owner);
        vm.expectRevert("TicketMachine: max owner mints exceeded");
        ticketMachine.ownerMint(10001); 
    }

}
