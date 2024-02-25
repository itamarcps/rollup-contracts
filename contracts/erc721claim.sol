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
    }

    uint256 private totalSupply_;
    uint256 private immutable maxSupply_;
    address private immutable signer_;
    mapping(uint256 => MintedToken) private mintedTokens_;
    

    /// Initialize the contract with the max supply and the signer address
    constructor(uint256 maxSupplyInit, address signerInit) 
            ERC721("MyTokenClaimable", "MTC") {
        maxSupply_ = maxSupplyInit;
        signer_ = signerInit;
    }

    // Function to mint a token for a user
    function mint(uint256 tokenId, address user, uint8 v, bytes32 r, bytes32 s) external {
        require(!mintedTokens_[tokenId].exists, "MyTokenClaimable: token already minted");
        // Create the message hash based on the tokenId and the user address
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, user));
        // Console.log the message hash
        console.logBytes32(messageHash);
        // Console.log the abi.encode(tokenId, user)
        console.logBytes(abi.encodePacked(tokenId, user));
        // Recover the signer from the signature
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, messageHash));
        address recoveredSigner = ecrecover(prefixedHashMessage, v, r, s);
        // Ensure the recovered signer is the same as the contract's signer
        require(recoveredSigner == signer_, "MyTokenClaimable: invalid signature");
        // Record the token as minted for the user
        mintedTokens_[tokenId] = MintedToken(true, user, v, r, s);
        ++totalSupply_;
        _safeMint(user, tokenId);
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