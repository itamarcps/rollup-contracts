// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
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
  console.log("🚀 Claim token deployed successfully:", myTokenClaimable.target);
}

// Execute deployment function
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
