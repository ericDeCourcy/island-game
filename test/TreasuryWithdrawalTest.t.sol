// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "../src/TicketMachine.sol";
import "../src/Treasury.sol";
import "../src/IWETH9.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TreasuryWithdrawalTest is Test {
    TicketMachine ticketMachine;
    Treasury      treasury;

    IWETH9 weth = IWETH9(0x4200000000000000000000000000000000000006);

    address owner     = vm.addr(1);
    address user      = vm.addr(2);
    address recipient = vm.addr(3);
    address stranger  = vm.addr(4);

    uint256 constant INITIAL_PRICE       = 1e16;
    uint256 constant PRICE_INCREASE      = 1_002_500e12;
    uint256 constant SCALAR              = 1e18;

    function setUp() public {
        vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));

        // deploy Treasury
        Treasury treasuryImpl = new Treasury();
        bytes memory treasuryInit = abi.encodeWithSelector(
            Treasury.initialize.selector,
            owner
        );
        treasury = Treasury(address(new ERC1967Proxy(address(treasuryImpl), treasuryInit)));

        // deploy TicketMachine
        TicketMachine ticketImpl = new TicketMachine();
        bytes memory ticketInit = abi.encodeWithSelector(
            TicketMachine.initialize.selector,
            owner,
            address(treasury)
        );
        ticketMachine = TicketMachine(address(new ERC1967Proxy(address(ticketImpl), ticketInit)));
    }

    // --- helpers ---

    function _ticketPrice() internal view returns (uint256) {
        return INITIAL_PRICE * PRICE_INCREASE / SCALAR;
    }

    function _buyWithEth() internal returns (uint256 cost) {
        cost = _ticketPrice();
        vm.deal(user, cost);
        vm.prank(user);
        ticketMachine.buyTicket{value: cost}(user, 1, 0);
    }

    function _buyWithWeth() internal returns (uint256 cost) {
        cost = _ticketPrice();
        vm.deal(user, cost);
        vm.prank(user);
        weth.deposit{value: cost}();
        vm.prank(user);
        weth.approve(address(ticketMachine), cost);
        vm.prank(user);
        ticketMachine.buyTicket(user, 1, cost);
    }

    // --- treasury receives funds ---

    function test_treasury_hasWethAfterEthPurchase() public {
        uint256 cost = _buyWithEth();
        assertEq(weth.balanceOf(address(treasury)), cost);
    }

    function test_treasury_hasWethAfterWethPurchase() public {
        uint256 cost = _buyWithWeth();
        assertEq(weth.balanceOf(address(treasury)), cost);
    }

    // --- owner full withdrawal ---

    function test_claimFunds_fullWithdrawal_afterEthPurchase() public {
        uint256 cost = _buyWithEth();

        vm.prank(owner);
        treasury.claimFunds(0, recipient);

        assertEq(weth.balanceOf(recipient),          cost);
        assertEq(weth.balanceOf(address(treasury)),  0);
    }

    function test_claimFunds_fullWithdrawal_afterWethPurchase() public {
        uint256 cost = _buyWithWeth();

        vm.prank(owner);
        treasury.claimFunds(0, recipient);

        assertEq(weth.balanceOf(recipient),          cost);
        assertEq(weth.balanceOf(address(treasury)),  0);
    }

    // --- owner partial withdrawal ---

    function test_claimFunds_partialWithdrawal() public {
        uint256 cost = _buyWithEth();
        uint256 half = cost / 2;

        vm.prank(owner);
        treasury.claimFunds(half, recipient);

        assertEq(weth.balanceOf(recipient),         half);
        assertEq(weth.balanceOf(address(treasury)), cost - half);
    }

    // --- access control ---

    function test_claimFunds_revertsForNonOwner() public {
        _buyWithEth();

        vm.prank(stranger);
        vm.expectRevert();
        treasury.claimFunds(0, stranger);
    }

    function test_claimFunds_revertsForZeroRecipient() public {
        _buyWithEth();

        vm.prank(owner);
        vm.expectRevert("Treasury: Recipient is zero address");
        treasury.claimFunds(0, address(0));
    }

    function test_claimFunds_revertsIfAmountExceedsBalance() public {
        uint256 cost = _buyWithEth();

        vm.prank(owner);
        vm.expectRevert("Treasury: claim amount is too high");
        treasury.claimFunds(cost + 1, recipient);
    }

    // --- treasury is empty before any purchase ---

    function test_treasury_startsEmpty() public view {
        assertEq(weth.balanceOf(address(treasury)), 0);
    }

    function test_claimFunds_revertsIfTreasuryEmpty() public {
        vm.prank(owner);
        vm.expectRevert("Treasury: claim amount is too high");
        treasury.claimFunds(1, recipient);
    }
}
