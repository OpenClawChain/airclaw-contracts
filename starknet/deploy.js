// Deploy escrow contract using starknet.js v9 - simplified
import { RpcProvider, Account, hash, constants } from "starknet";
import fs from "fs";

// Read compiled contracts
const contractJson = JSON.parse(fs.readFileSync("./target/dev/airclaw_starknet_escrow.contract_class.json", "utf8"));
const compiledJson = JSON.parse(fs.readFileSync("./target/dev/airclaw_starknet_escrow.compiled_contract_class.json", "utf8"));

// Account
const accountAddress = "0x02eb0b878df018f7b9f722b7af6496f084b246597014d2886332ac2945431bf8";
const privateKey = "0x03750e5456f17426a87f70fbd6f2e47a82d95369da7b3cfe4605f79e42108821";
const rpcUrl = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_10/a0CQ0YnVGtptgWQBGvSXW";

async function deploy() {
  console.log("Connecting to", rpcUrl);
  
  // Create provider
  const provider = new RpcProvider({ 
    nodeUrl: rpcUrl,
    chainId: constants.StarknetChainId.SEPOLIA 
  });
  
  // Create account using options object
  const account = new Account({
    provider,
    address: accountAddress,
    signer: privateKey
  });
  console.log("Account:", accountAddress);

  // Get nonce
  const nonce = await account.getNonce();
  console.log("Nonce:", nonce);

  // Calculate class hash from Sierra program
  const classHash = hash.computeContractClassHash(contractJson);
  console.log("Class hash:", classHash);

  // Calculate compiled class hash
  const compiledClassHash = hash.computeCompiledClassHash(compiledJson);
  console.log("Compiled class hash:", compiledClassHash);

  // Declare with V3 transaction - using raw contract class
  console.log("Declaring contract (V3)...");
  const declareResponse = await account.declare({
    classHash: classHash,
    contract: contractJson,
    compiledClassHash: compiledClassHash,
  });
  console.log("Declared! Transaction:", declareResponse.transaction_hash);
  console.log("Declared class hash:", declareResponse.class_hash);

  // Wait for declare
  console.log("Waiting for declare confirmation...");
  await provider.waitForTransaction(declareResponse.transaction_hash);
  console.log("Declare confirmed!");

  // Deploy
  console.log("Deploying contract...");
  const deployResponse = await account.deployContract({
    classHash: declareResponse.class_hash,
    constructorCalldata: [accountAddress],
  });
  console.log("Deployed!");
  console.log("Contract address:", deployResponse.contract_address);

  // Save
  fs.writeFileSync("./deployed-address.txt", deployResponse.contract_address);
  fs.writeFileSync("./deployment-info.json", JSON.stringify({
    address: deployResponse.contract_address,
    txHash: deployResponse.transaction_hash,
    classHash: declareResponse.class_hash,
    deployer: accountAddress,
  }, null, 2));
  console.log("Saved to deployed-address.txt and deployment-info.json");
}

deploy().catch(e => {
  console.error("Error:", e.message || e);
  if (e.response?.error?.message) {
    console.error("RPC Error:", e.response.error.message);
  }
  process.exit(1);
});
