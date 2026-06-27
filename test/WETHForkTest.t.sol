// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "../src/IWETH9.sol";

contract WETHForkTest is Test {
    IWETH9 weth = IWETH9(0x4200000000000000000000000000000000000006);

    address user = address(0x1234567890);

    function setUp() public {
        vm.createSelectFork(vm.envString("OPTIMISM_RPC_URL"));
    }

    // will fail if not on optimism — no code at this address on other chains
    function test_fork_wethHasCode() public view {
        assertGt(address(weth).code.length, 0, "No code at WETH address - are you forking Optimism?");
    }

    // will fail if not on optimism — name is chain-specific
    function test_fork_wethNameAndSymbol() public view {
        assertEq(weth.name(),   "Wrapped Ether");
        assertEq(weth.symbol(), "WETH");
        assertEq(weth.decimals(), 18);
    }

    // will fail if deposit() isn't live on the fork
    function test_fork_deposit() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(user), 1 ether);
    }

    // will fail if withdraw() isn't live on the fork
    function test_fork_withdraw() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        weth.deposit{value: 1 ether}();

        vm.prank(user);
        vm.txGasPrice(0);  // zero gas price so gas cost doesn't matter
        weth.withdraw(1 ether);

        assertEq(weth.balanceOf(user), 0);
        assertEq(user.balance, 1 ether);
    }

    // will fail if transfer() isn't live on the fork
    function test_fork_transfer() public {
        address recipient = makeAddr("recipient");

        vm.deal(user, 1 ether);
        vm.prank(user);
        weth.deposit{value: 1 ether}();

        vm.prank(user);
        weth.transfer(recipient, 1 ether);

        assertEq(weth.balanceOf(user),      0);
        assertEq(weth.balanceOf(recipient), 1 ether);
    }

    // will fail if approve/transferFrom aren't live on the fork
    function test_fork_approveAndTransferFrom() public {
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");

        vm.deal(user, 1 ether);
        vm.prank(user);
        weth.deposit{value: 1 ether}();

        vm.prank(user);
        weth.approve(spender, 1 ether);
        assertEq(weth.allowance(user, spender), 1 ether);

        vm.prank(spender);
        weth.transferFrom(user, recipient, 1 ether);
        assertEq(weth.balanceOf(recipient), 1 ether);
        assertEq(weth.allowance(user, spender), 0);
    }
}
