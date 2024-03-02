const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyToken Lifecycle Test", function () {
  let MyTokenMintable, myTokenMintable;
  let MyTokenClaimable, myTokenClaimable;
  let owner, addr1, addr2, signer;
  let tokenId = 0;
  let signature, splitSignature;

  before(async function () {
    // Get signers
    [owner, addr1, addr2, signer] = await ethers.getSigners();
    // Deploy MyTokenMintable contract
    MyTokenMintable = await ethers.getContractFactory("MyTokenMintable");
    myTokenMintable = await MyTokenMintable.deploy(
      100,
      signer.address,
      "http://localhost/testuri/"
    );

    // Deploy MyTokenClaimable contract
    MyTokenClaimable = await ethers.getContractFactory("MyTokenClaimable");
    myTokenClaimable = await MyTokenClaimable.deploy(
      100,
      signer.address,
      "http://localhost/testuri/"
    );

    // Wait for the contracts to be mined
    await myTokenMintable.waitForDeployment();
    await myTokenClaimable.waitForDeployment();

    console.log("🚀 Mint token deployed successfully:", myTokenMintable.target);
    console.log(
      "🚀 Claim token deployed successfully:",
      myTokenClaimable.target
    );
  });

  it("Mint a token", async function () {
    await myTokenMintable.connect(owner).mint(addr1.address);
    console.log("Token 0 minted to: ", addr1.address);
    expect(await myTokenMintable.ownerOf(tokenId)).to.equal(addr1.address);
  });

  it("Mint several tokens from different addresses and verify ownership", async function () {
    // Define the addresses
    const addresses = [addr1.address, addr2.address]; // Add more addresses if needed

    // Define the number of tokens to mint for each address
    const numTokensToMint = 0;

    // Mint tokens for each address
    for (const address of addresses) {
      for (let i = 0; i < numTokensToMint; i++) {
        await myTokenMintable.connect(owner).mint(address);
      }
    }

    // Validate the ownership of minted tokens
    for (const address of addresses) {
      const tokenIds = await myTokenMintable.getAllTokensOwnedByUser(address);
      for (let i = 0; i < numTokensToMint; i++) {
        expect(await myTokenMintable.ownerOf(tokenIds[i])).to.equal(address);
      }
    }
  });

  it("should return the URI for a given token ID", async function () {
    // Call the function to get the token URI
    const _tokenURI = await myTokenMintable.tokenURI(tokenId);

    // Assert that the token URI is not null or undefined
    expect(_tokenURI).to.not.be.null;
    expect(_tokenURI).to.not.be.undefined;

    // You can add additional assertions here if needed
    console.log(_tokenURI);
  });

  it("Check for minted 0 tokenId", async function () {
    // Call the function to get the token URI
    const _tokenURI = await myTokenMintable.tokenURI(0);

    // Assert that the token URI is not null or undefined
    expect(_tokenURI).to.not.be.null;
    expect(_tokenURI).to.not.be.undefined;

    // You can add additional assertions here if needed
    console.log("zero token uri", _tokenURI);
  });

  it("Preburn the token", async function () {
    await myTokenMintable.connect(addr1).preBurn(tokenId);
    // Implement your checks for preburn logic here
  });

  it("Sign the burn message", async function () {
    // /// Encode the mensage hash using abi.encodePackedx
    // const AbiCoder = new ethers.AbiCoder();
    // // Print AbiCoder.encode(["uint256", "address"], [tokenId, addr1.address]);
    // console.log(
    //   AbiCoder.encode(["uint256", "address"], [tokenId, addr1.address])
    // );
    // print MyTokenMintable.message(tokenId, MyTokenMintable.preBurnedTokens(tokenId).user);
    let preBurnedTokens = await myTokenMintable.preBurnedTokens(tokenId);
    // console.log(await myTokenMintable.message(tokenId, preBurnedTokens.user));
    const messageHash = ethers.solidityPackedKeccak256(
      ["uint256", "address", "uint256"],
      [tokenId, preBurnedTokens.user, preBurnedTokens.rarity]
    );

    // Sign the message hash (**DO NOT FORGET, WE ARE HASHING THE BYTES32 MESSAGE HASH, NOT A JS STRING!!!**)
    signature = await signer.signMessage(ethers.toBeArray(messageHash));
    // // print signature owner address
    // console.log(await signer.getAddress());

    splitSignature = ethers.Signature.from(signature);
    let address = ethers.verifyMessage(
      ethers.toBeArray(messageHash),
      splitSignature
    );

    // console.log("js derived address: " + address);
  });

  it("Burn the token", async function () {
    // // Print V
    // console.log("v" + splitSignature.v);
    // // Print R
    // console.log("r" + splitSignature.r);
    // // Print S
    // console.log("s" + splitSignature.s);
    await myTokenMintable
      .connect(signer)
      .burn(tokenId, splitSignature.v, splitSignature.r, splitSignature.s);
  });

  it("Claim the token", async function () {
    let preBurnedTokens = await myTokenMintable.preBurnedTokens(tokenId);
    await myTokenClaimable
      .connect(addr2)
      .mint(
        tokenId,
        preBurnedTokens.rarity,
        addr1.address,
        splitSignature.v,
        splitSignature.r,
        splitSignature.s
      );
  });
});
