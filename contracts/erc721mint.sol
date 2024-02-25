// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract MyTokenMintable is ERC721 {

    struct BurnedToken {
        bool exists;
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    uint256 private tokenIdCounter_;
    uint256 private totalSupply_;
    uint256 private immutable maxSupply_;
    address private immutable signer_;
    mapping (uint256 => BurnedToken) private preBurnedTokens_;
    mapping (uint256 => BurnedToken) private burnedTokens_;

    /// Initialize the contract with the max supply and the signer address
    constructor(uint256 maxSupplyInit, address signerInit) 
            ERC721("MyTokenMintable", "MTM") {
        tokenIdCounter_ = 0;
        totalSupply_ = 0;
        maxSupply_ = maxSupplyInit;
        signer_ = signerInit;
    }

    function mint(address to) external {
        require(tokenIdCounter_ < maxSupply_, "MyTokenMintable: max supply reached");
        _safeMint(to, tokenIdCounter_);
        tokenIdCounter_++;
        totalSupply_++;
    }

    function preBurn(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "MyTokenMintable: caller is not the owner");
        // burn the token
        _burn(tokenId);
        // Annotate the tokenId and the user (who is the owner of the token) as pre-burned
        preBurnedTokens_[tokenId] = BurnedToken(true, _msgSender(), 0, 0x0, 0x0);
    }

    function burn(uint256 tokenId, uint8 v, bytes32 r, bytes32 s) external {
        require(preBurnedTokens_[tokenId].exists, "MyTokenMintable: token is not pre-burned");
        // CONSOLE.LOG v, r, s
        console.log("v,r,s");
        console.log(v);
        console.logBytes32(r);
        console.logBytes32(s);
        // Create the message hash based on the tokenId and the user, use abi non-standard packed encoding
    
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, preBurnedTokens_[tokenId].user));
        // Console.log "solidity message hash:"
        console.log("solidity message hash:");
        // Console.log the message hash
        console.logBytes32(messageHash);
        // Console.log the abi.encode(tokenId, preBurnedTokens_[tokenId].user)
        console.logBytes(abi.encodePacked(tokenId, preBurnedTokens_[tokenId].user));        
        // Now, we do ecrecover to get the address of the signer
        address recoveredSigner = ecrecover(messageHash, v, r, s);
        // console.log the recovered signer
        console.logAddress(recoveredSigner);
        // console.log the signer
        console.logAddress(signer_);
        // Check if the signer is the same as the signer of the contract
        require(recoveredSigner == signer_, "MyToken Mintable: invalid signature");
        // Annotate the tokenId and the user (who is the owner of the token) as burned
        burnedTokens_[tokenId] = BurnedToken(true, preBurnedTokens_[tokenId].user, v, r, s);
        // Remove the tokenId from the pre-burned tokens
        delete preBurnedTokens_[tokenId];
    }

    function message (uint256 tokenId, address user) external pure returns (bytes memory) {
        return abi.encode(tokenId, user);
    }



    /// Getter for the total supply
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /// Getter for the max supply
    function maxSupply() external view returns (uint256) {
        return maxSupply_;
    }

    /// Getter for the signer
    function signer() external view returns (address) {
        return signer_;
    }

    /// Getter for the pre-burned tokens
    function preBurnedTokens(uint256 tokenId) external view returns (BurnedToken memory) {
        return preBurnedTokens_[tokenId];
    }

    /// Getter for the burned tokens
    function burnedTokens(uint256 tokenId) external view returns (BurnedToken memory) {
        return burnedTokens_[tokenId];
    }

    /// Getter for the tokenIdCounter
    function tokenIdCounter() external view returns (uint256) {
        return tokenIdCounter_;
    }
}
