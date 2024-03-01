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
    myTokenMintable = await MyTokenMintable.deploy(100, signer.address);

    // Deploy MyTokenClaimable contract
    MyTokenClaimable = await ethers.getContractFactory("MyTokenClaimable");
    myTokenClaimable = await MyTokenClaimable.deploy(100, signer.address);

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
    expect(await myTokenMintable.ownerOf(tokenId)).to.equal(addr1.address);
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
      ["uint256", "address"],
      [tokenId, preBurnedTokens.user]
    );
    // print the message hash
    // console.log(messageHash);
    // print MyTokenMintable.messageHash(tokenId, MyTokenMintable.preBurnedTokens(tokenId).user);

    // Sign the message hash (**DO NOT FORGET, WE ARE HASHING THE BYTES32 MESSAGE HASH, NOT A JS STRING!!!**)
    signature = await signer.signMessage(ethers.toBeArray(messageHash));
    // // print signature owner address
    // console.log(await signer.getAddress());
    // // print myTokenMintable.signer();
    // console.log(await myTokenMintable.signer());
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
    await myTokenClaimable
      .connect(addr2)
      .mint(
        tokenId,
        addr1.address,
        splitSignature.v,
        splitSignature.r,
        splitSignature.s
      );
  });
});
