// duplicated for using in test cases since it doesn't support export default
const { utils } = require("ethers");

// Function to generate a custom structured signature using the EIP712 Domain
const TokenSignature = async (tokenId, owner, signingContract, provider) => {
  try {
    // Fetch the nonce for the owner from the contract (remove if we don't need noncing)
    // const nonce = await signingContract.nonces(owner);

    // Fetch the name of the contract
    const contractName = await signingContract.name();
    console.log("contractName", contractName);

    // Define EIP712 Domain fields
    const EIP712Domain = [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" },
    ];

    // Define Message Type fields
    const TokenSignParams = [
      { name: "tokenId", type: "bytes32" },
      //   { name: "nonce", type: "uint256" },
    ];

    // Construct EIP712 Domain
    const domain = {
      name: contractName,
      version: "1",
      chainId: provider.network.chainId,
      verifyingContract: signingContract.address,
    };
    console.log("chainId", provider.network.chainId);
    console.log("contract address", signingContract.address);
    // Construct Message Object
    const message = {
      tokenId,
      //   nonce: nonce.toHexString(),
    };

    // Serialize Data
    const data = JSON.stringify({
      types: { EIP712Domain, TokenSignParams },
      domain,
      primaryType: "TokenSignParams",
      message,
    });

    // Sign Data using eth_signTypedData_v4 method
    const signature = await provider.send("eth_signTypedData_v4", [
      owner,
      data,
    ]);

    // // Extract Signature Components
    const signData = utils.splitSignature(signature);
    const { r, s, v } = signData;

    // Return Signature Components along with other data
    return {
      r,
      s,
      v,
      signature,
      isRejected: false,
    };
  } catch (e) {
    // Handle errors and return appropriate response
    console.log("error", e);
    return {
      r: undefined,
      s: undefined,
      v: undefined,
      signature: undefined,
      isRejected: true,
    };
  }
};

module.exports = TokenSignature;
