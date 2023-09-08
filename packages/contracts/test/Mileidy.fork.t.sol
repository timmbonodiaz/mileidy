// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2, stdStorage, StdStorage} from "forge-std/Test.sol";

import {AddressBook} from "./utils/AddressBook.sol";
import {Mileidy} from "../src/Mileidy.sol";

contract MileidyForkTest is Test, AddressBook {
    address MILADY_OWNER = vm.envAddress("MILADY_OWNER");
    address REMILIO_OWNER = vm.envAddress("REMILIO_OWNER");
    address PIXELADY_OWNER = vm.envAddress("PIXELADY_OWNER");

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    uint256 MAINNET_BLOCK = vm.envUint("MAINNET_BLOCK");

    Mileidy private nft;
    uint256 private price;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(MAINNET_BLOCK);

        nft = new Mileidy("https://ipfs.io/", OWNER);
        price = nft.MINT_PRICE();
    }

    function test_mint_Milady() public {
        _test_mint(MILADY_OWNER, MILADY_OWNER);
    }

    function test_mint_Remilio() public {
        _test_mint(REMILIO_OWNER, REMILIO_OWNER);
    }

    function test_mint_Pixelady() public {
        _test_mint(PIXELADY_OWNER, PIXELADY_OWNER);
    }

    function test_multi_Milady() public {
        _test_mint(MILADY_OWNER, MILADY_OWNER);
    }

    function test_multi_Remilio() public {
        _test_mint(REMILIO_OWNER, REMILIO_OWNER);
    }

    function test_multi_Pixelady() public {
        _test_mint(PIXELADY_OWNER, PIXELADY_OWNER);
    }

    function test_gift_Milady() public {
        _test_mint(MILADY_OWNER, BOB);
    }

    function test_gift_Remilio() public {
        _test_mint(REMILIO_OWNER, BOB);
    }

    function test_gift_Pixelady() public {
        _test_mint(PIXELADY_OWNER, BOB);
    }

    function test_mint_RevertIf_MintWithoutMilady() public {
        vm.expectRevert(Mileidy.NotMilady.selector);
        nft.mintlady(BOB);
    }

    /// @dev Helper functions to test minting
    function _test_mint(address from, address to) internal {
        vm.startPrank(from);
        nft.mintlady(to);
        vm.stopPrank();
        assertEq(nft.balanceOf(to), 1);
    }
}
