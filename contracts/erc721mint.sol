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
        uint256 rarity;
    }

    string private _tokenBaseURI;

    uint256 private tokenIdCounter_;
    uint256 private totalSupply_;
    uint256 private immutable maxSupply_;   
    address private immutable signer_;
    address private owner_;
    mapping (uint256 => BurnedToken) private preBurnedTokens_;
    mapping (uint256 => BurnedToken) private burnedTokens_;
    mapping (uint256 => uint256) private tokenIdRarity_;

    // Event
    // Event to log preBurn 
    event PreBurnedEvent(
        uint256 tokenId,
        address claimableOwner,
        uint256 rarity
    );
    // Event to log Metadata URI update 
    event MetadataUpdate(uint256 tokenId);

    /// Initialize the contract with the max supply and the signer address
    constructor(uint256 maxSupplyInit, address signerInit, string memory baseURI) // Name and ticker of the token
        ERC721("MyTokenMintable", "MTM") {
        // Contract parameters initialization
        owner_ = msg.sender;
        _tokenBaseURI = baseURI;
        tokenIdCounter_ = 0;
        totalSupply_ = 0;
        maxSupply_ = maxSupplyInit;
        signer_ = signerInit;
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


    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     override(ERC721, ERC721URIStorage)
    //     returns (string memory)
    // {
    //     return super.tokenURI(tokenId);
    // }

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

    function mint(address to) external {
        require(tokenIdCounter_ < maxSupply_, "MyTokenMintable: max supply reached");
        // Mint the NFT to the user's provided address
        _safeMint(to, tokenIdCounter_);
        // Set the token URI
        tokenIdRarity_[tokenIdCounter_] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, tokenIdCounter_))) % 3;
        // Set the URi for the token with gold, silver and broze strings
        _setTokenURI(tokenIdCounter_, _getTokenRarityString(tokenIdRarity_[tokenIdCounter_]));
        // Housekeeping parameters
        tokenIdCounter_++;
        totalSupply_++;
    }

    function preBurn(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "MyTokenMintable: caller is not the owner");
        // burn the token
        _burn(tokenId);
        // Annotate the tokenId and the user (who is the owner of the token) as pre-burned
        preBurnedTokens_[tokenId] = BurnedToken(true, _msgSender(), 0, 0x0, 0x0, tokenIdRarity_[tokenId]);
        // Emit Preburned event
        emit PreBurnedEvent(tokenId, _msgSender(), tokenIdRarity_[tokenId]);
    }

    function burn(uint256 tokenId, uint8 v, bytes32 r, bytes32 s) external {
        require(preBurnedTokens_[tokenId].exists, "MyTokenMintable: token is not pre-burned");

        // Create the message hash based on the tokenId and the user, use abi non-standard packed encoding
        bytes32 messageHash = keccak256(message(tokenId, preBurnedTokens_[tokenId].user));
        // Hash the message to standardize EIP 712 without Domain for using eth_sign in ethers
        address recoveredSigner = ecrecover(_toTyped32ByteDataHash(messageHash), v, r, s);  

        // Check if the signer is the same as the signer of the contract
        require(recoveredSigner == signer_, "MyToken Mintable: invalid signature");
        // Annotate the tokenId and the user (who is the owner of the token) as burned
        burnedTokens_[tokenId] = BurnedToken(true, preBurnedTokens_[tokenId].user, v, r, s, tokenIdRarity_[tokenId]);
        // Remove the tokenId from the pre-burned tokens
        delete preBurnedTokens_[tokenId];
    }

    function message (uint256 tokenId, address user) public view returns (bytes memory) {
        return abi.encodePacked(tokenId, user, tokenIdRarity_[tokenId]);
    }

    function _toTyped32ByteDataHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
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
