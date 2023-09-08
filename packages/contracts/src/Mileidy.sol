// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "solady/tokens/ERC721.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Ownable} from "solady/auth/Ownable.sol";

import {AddressBook} from "./AddressBook.sol";

/// @notice Milady meme derivative
/// @author @timmbonodiaz
/// @author shout-out @vectorized for the amazing solady lib
contract Mileidy is ERC721, Ownable {
    /// @notice Thrown when the mint price is not paid
    error MintPriceNotPaid();

    /// @dev Only miladys can mint for free
    error NotMilady();

    /// @notice Thrown when the max supply is reached
    error MaxSupply();

    /// @notice Total supply of the token
    uint256 public constant TOTAL_SUPPLY = 10_000;

    /// @notice Mint price (non miladys)
    uint256 public constant MINT_PRICE = 0.003 ether;

    /// @notice Base URI for the token
    string public baseURI;

    /// @notice Total supply of the token
    uint256 public totalSupply;

    /// @notice Constructor
    /// @param _baseURI Base URI for the token
    /// @param _owner Owner of the contract
    constructor(string memory _baseURI, address _owner) {
        baseURI = _baseURI;
        _initializeOwner(_owner);
        _safeMint(_owner, ++totalSupply);
    }

    /// @notice Mint a new token
    /// @param recipient Address of the recipient
    /// @param count Number of tokens to mint
    function mint(address recipient, uint8 count) external payable {
        if (msg.value != (MINT_PRICE * count)) {
            revert MintPriceNotPaid();
        }
        _doMint(recipient, count);
    }

    /// @notice Free mint for milady holders
    /// @param recipient Address of the recipient
    function mintlady(address recipient) external payable {
        if (!AddressBook.isMilady(msg.sender)) {
            revert NotMilady();
        }
        _doMint(recipient, 1);
    }

    /// @notice Mint a new token
    /// @param recipient Address of the recipient
    /// @param count Number of tokens to mint
    /// @dev 5% mileidys devs & arts alloc
    function _doMint(address recipient, uint256 count) internal virtual {
        if ((totalSupply + count) > TOTAL_SUPPLY) revert MaxSupply();

        for (uint256 i = 0; i < count; i++) {
            _safeMint(recipient, ++totalSupply);
            if (totalSupply < TOTAL_SUPPLY && totalSupply % 20 == 0) {
                _safeMint(owner(), ++totalSupply);
            }
        }

        /// @dev catch alloc edge cases
        if (totalSupply > TOTAL_SUPPLY) revert MaxSupply();
    }

    /// @notice Get metadata URI for a given token
    /// @param id ID of the token
    /// @return URI unique uri for the token
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (!_exists(id) || bytes(baseURI).length == 0) revert TokenDoesNotExist();
        return string.concat(baseURI, LibString.toString(id));
    }

    /// @notice Set the base URI for the token
    /// @param _baseURI New base URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Withdraw funds from the contract
    /// @param payee Address of the recipient
    /// @return success Whether the transfer was successful
    function withdraw(address payable payee) external onlyOwner returns (bool success) {
        if (payee == address(0) || payee == address(this)) {
            revert TransferToZeroAddress();
        }

        uint256 balance = address(this).balance;

        // slither-disable-next-line low-level-calls
        (success,) = payee.call{value: balance}("");
        return success;
    }

    /// @notice Name of the token
    function name() public view virtual override returns (string memory) {
        return "Mileidy";
    }

    /// @notice Symbol of the token
    function symbol() public view virtual override returns (string memory) {
        return "LLADY";
    }
}
