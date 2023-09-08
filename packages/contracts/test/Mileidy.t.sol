// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2, stdStorage, StdStorage} from "forge-std/Test.sol";

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ERC721Recipient} from "solady-test/ERC721.t.sol";

import {AddressBook} from "./utils/AddressBook.sol";
import {Mileidy} from "../src/Mileidy.sol";

contract MileidyTest is Test, AddressBook {
    using stdStorage for StdStorage;

    Mileidy private nft;
    uint256 private price;

    function setUp() public {
        nft = new Mileidy("https://ipfs.io/", OWNER);
        price = nft.MINT_PRICE();
    }

    function test_token_name() public {
        assertEq(nft.name(), "Mileidy");
    }

    function test_token_symbol() public {
        assertEq(nft.symbol(), "LLADY");
    }

    function test_mint_MintComplete() public {
        nft.mint{value: price}(BOB, 1);
        assertEq(nft.balanceOf(BOB), 1);
        assertEq(address(nft).balance, price);
    }

    function test_mint_PricePaid() public {
        assertEq(address(nft).balance, 0);

        nft.mint{value: price}(BOB, 1);
        assertEq(address(nft).balance, price);

        nft.mint{value: price}(BOB, 1);
        assertEq(address(nft).balance, price * 2);
    }

    function test_mint_RevertIf_MintWithoutValue() public {
        vm.expectRevert(Mileidy.MintPriceNotPaid.selector);
        nft.mint(BOB, 1);
    }

    function test_mint_RevertIf_MaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nft)).sig("totalSupply()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(nft.TOTAL_SUPPLY()));
        vm.store(address(nft), loc, mockedCurrentTokenId);

        vm.expectRevert(Mileidy.MaxSupply.selector);
        nft.mint{value: price}(BOB, 1);
    }

    function test_mint_RevertIf_MintToZeroAddress() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        nft.mint{value: price}(address(0), 1);
    }

    function test_mint_BalanceIncremented() public {
        nft.mint{value: price}(BOB, 1);
        uint256 slotBalance = stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(BOB).find();

        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mint{value: price}(BOB, 1);
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function test_mint_SafeContractReceiver() public {
        ERC721Recipient receiver = new ERC721Recipient();
        nft.mint{value: price}(address(receiver), 1);
        uint256 slotBalance =
            stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(receiver)).find();

        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    function test_mint_RevertUnSafeContractReceiver() public {
        vm.etch(ALICE, bytes("mock code"));
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        nft.mint{value: price}(ALICE, 1);
    }

    function test_multi_MultiMint() public {
        nft.mint{value: price * 2}(BOB, 2);
        assertEq(nft.balanceOf(BOB), 2);
        assertEq(address(nft).balance, price * 2);
    }

    function test_multi_MaxMint() public {
        nft.mint{value: price * 255}(BOB, 255);
        assertEq(nft.balanceOf(BOB), 255);
    }

    function test_multi_FuzzMint(uint8 n) public {
        nft.mint{value: price * n}(BOB, n);
        assertEq(nft.balanceOf(BOB), n);
    }

    function test_multi_RevertIf_MintUnderpayment() public {
        vm.expectRevert(Mileidy.MintPriceNotPaid.selector);
        nft.mint{value: price}(BOB, 2);
    }

    function test_multi_RevertIf_MintOverpayment() public {
        vm.expectRevert(Mileidy.MintPriceNotPaid.selector);
        nft.mint{value: price * 2}(BOB, 1);
    }


    function test_uri_GetTokenURI() public {
        nft.mint{value: price}(BOB, 1);
        string memory uri = nft.tokenURI(1);
        assertEq(uri, "https://ipfs.io/1");
    }

    function test_uri_RevertIf_NonExistentTokenURI() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        nft.tokenURI(100);
    }

    function test_uri_SetBaseURIAsOwner() public {
        nft.mint{value: price}(BOB, 1);

        vm.prank(OWNER);
        nft.setBaseURI("https://ipfs.io/#");

        string memory uri = nft.tokenURI(1);
        assertEq(uri, "https://ipfs.io/#1");
    }

    function test_uri_RevertIf_BaseURIIsEmpty() public {
        nft.mint{value: price}(BOB, 1);

        vm.prank(OWNER);
        nft.setBaseURI("");

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        nft.tokenURI(1);
    }

    function test_uri_FixBaseURI() public {
        nft.mint{value: price}(BOB, 1);
        string memory uri = nft.tokenURI(1);
        assertEq(uri, "https://ipfs.io/1");

        vm.prank(OWNER);
        nft.setBaseURI("");

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        uri = nft.tokenURI(1);

        vm.prank(OWNER);
        nft.setBaseURI("https://ipfs.io/");

        uri = nft.tokenURI(1);
        assertEq(uri, "https://ipfs.io/1");
    }

    function test_uri_RevertIf_SetBaseURIAsNonOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        nft.setBaseURI("https://ipfs.io/#");
    }

    function test_withdraw_WithdrawFunds() public {
        nft.mint{value: price}(BOB, 1);
        nft.mint{value: price}(BOB, 1);
        nft.mint{value: price}(BOB, 1);

        assertEq(address(nft).balance, price * 3);

        vm.prank(OWNER);
        nft.withdraw(payable(ALICE));

        assertEq(address(nft).balance, 0);
        assertEq(ALICE.balance, price * 3);
    }

    function test_withdraw_RevertIf_WithdrawAsNonOwner() public {
        vm.expectRevert(Ownable.Unauthorized.selector);
        nft.withdraw(payable(BOB));
    }

    function test_withdraw_RevertIf_WithdrawToZeroAddress() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        vm.prank(OWNER);
        nft.withdraw(payable(address(0)));
    }

    function test_withdraw_RevertIf_WithdrawToSelf() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        vm.prank(OWNER);
        nft.withdraw(payable(address(nft)));
    }

    function test_supply_CountNFTs() public {
        assertEq(nft.totalSupply(), 1);

        nft.mint{value: price}(BOB, 1);
        assertEq(nft.totalSupply(), 2);

        nft.mint{value: price}(BOB, 1);
        assertEq(nft.totalSupply(), 3);
    }

    function test_supply_MaxSupply() public {
        assertEq(nft.totalSupply(), 1);

        uint256 slot = stdstore.target(address(nft)).sig("totalSupply()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(nft.TOTAL_SUPPLY() - 1));
        vm.store(address(nft), loc, mockedCurrentTokenId);

        nft.mint{value: price}(BOB, 1);
        assertEq(nft.totalSupply(), nft.TOTAL_SUPPLY());
    }

    function test_alloc_FirstMint() public {
        assertEq(nft.totalSupply(), 1);
        nft.mint{value: price * 20}(BOB, 20);
        assertEq(nft.balanceOf(OWNER), 2);
    }

    function test_alloc_TotalSupply() public {
        assertEq(nft.totalSupply(), 1);

        for (uint256 i = 0; i < 47; i++) {
            nft.mint{value: price * 200}(BOB, 200);
        }
        nft.mint{value: price * 100}(BOB, 100);

        assertEq(nft.totalSupply(), nft.TOTAL_SUPPLY());
        assertEq(nft.ownerOf(1), OWNER);
        assertEq(nft.ownerOf(10_000), BOB);
        assertEq(nft.balanceOf(OWNER), 500);
        assertEq(nft.balanceOf(BOB), 9500);
    }

    function test_alloc_RevertIf_Overmint() public {
        uint256 slot = stdstore.target(address(nft)).sig("totalSupply()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(nft.TOTAL_SUPPLY() - 30));
        vm.store(address(nft), loc, mockedCurrentTokenId);

        vm.expectRevert(Mileidy.MaxSupply.selector);
        nft.mint{value: price * 30}(BOB, 30);
    }
}
