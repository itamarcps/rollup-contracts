// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract MyTokenClaimable is ERC721 {
    struct MintedToken {
        bool exists;
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 rarity;
    }

    address private owner_;

    uint256 private totalSupply_;
    uint256 private immutable maxSupply_;
    address private immutable signer_;
    mapping(uint256 => MintedToken) private mintedTokens_;
    // Base URI
    string private _tokenBaseURI;
    // Event to log Metadata URI update 
    event MetadataUpdate(uint256 tokenId);

    /// Initialize the contract with the max supply and the signer address
    constructor(uint256 maxSupplyInit, address signerInit, string memory baseURI) 
        ERC721("MyTokenClaimable", "MTC") {
        // Contract parameters initialization
        owner_ = msg.sender;

        _tokenBaseURI = baseURI;
        totalSupply_ = 0;

        maxSupply_ = maxSupplyInit;
        signer_ = signerInit;
        owner_ = msg.sender;
    }

    function setBaseURI(string memory baseURI) external {
        require (owner_ == msg.sender, "SETBASEURI NOT OWNER");
        _tokenBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    // Optional mapping for token URIs
    mapping(uint256 tokenId => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    function _getTokenRarityString(uint256 tokenRarity) internal pure returns (string memory) {
        if (tokenRarity == 0) {
            return "gold";
        } else if (tokenRarity == 1) {
            return "silver";
        } else if (tokenRarity == 2) {
            return "bronze";
        } else {
            revert("Invalid token rarity");
        }
    }

    // Function to mint a token for a user
    function mint(uint256 tokenId, uint256 rarity, address user, uint8 v, bytes32 r, bytes32 s) external {
        require(!mintedTokens_[tokenId].exists, "MyTokenClaimable: token already minted");
        // Create the message hash based on the tokenId and the user address
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, user, rarity));
        // Recover the signature
        address recoveredSigner = ecrecover(_toTyped32ByteDataHash(messageHash), v, r, s);

        // Ensure the recovered signer is the same as the contract's signer
        require(recoveredSigner == signer_, "MyTokenClaimable: invalid signature");
        
        // Record the token as minted for the user
        mintedTokens_[tokenId] = MintedToken(true, user, v, r, s, rarity);
        ++totalSupply_;
        _safeMint(user, tokenId);
        // Set the URi for the token with gold, silver and broze strings
        _setTokenURI(tokenId, _getTokenRarityString(rarity));
    }


    function _toTyped32ByteDataHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    // Getter for the total supply of minted tokens
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    // Getter for the max supply
    function maxSupply() external view returns (uint256) {
        return maxSupply_;
    }

    // Getter for the signer address
    function signer() external view returns (address) {
        return signer_;
    }

    // Getter for the minted tokens
    function mintedTokens(uint256 tokenId) external view returns (MintedToken memory) {
        require(mintedTokens_[tokenId].exists, "MyTokenClaimable: token not minted");
        return mintedTokens_[tokenId];
    }
}