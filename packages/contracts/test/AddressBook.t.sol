// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2, stdStorage, StdStorage} from "forge-std/Test.sol";

import {IERC20, AddressBook} from "../src/AddressBook.sol";

contract AddressBookTest is Test {
    address MILADY_OWNER = vm.envAddress("MILADY_OWNER");
    address REMILIO_OWNER = vm.envAddress("REMILIO_OWNER");
    address PIXELADY_OWNER = vm.envAddress("PIXELADY_OWNER");
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    uint256 MAINNET_BLOCK = vm.envUint("MAINNET_BLOCK");

    function setUp() public {
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(MAINNET_BLOCK);
    }

    function test_balance_Milady() public {
        assertGt(IERC20(AddressBook.MILADY).balanceOf(MILADY_OWNER), 0);
    }

    function test_balance_Remilio() public {
        assertGt(IERC20(AddressBook.REMILIO).balanceOf(REMILIO_OWNER), 0);
    }

    function test_balance_Pixelady() public {
        assertGt(IERC20(AddressBook.PIXELADY).balanceOf(PIXELADY_OWNER), 0);
    }

    function test_check_Milady() public {
        assertTrue(AddressBook.isMilady(MILADY_OWNER));
    }

    function test_check_Remilio() public {
        assertTrue(AddressBook.isMilady(REMILIO_OWNER));
    }

    function test_check_Pixelady() public {
        assertTrue(AddressBook.isMilady(PIXELADY_OWNER));
    }

    function test_check_EmptyAddress() public {
        assertFalse(AddressBook.isMilady(address(1)));
    }
}
