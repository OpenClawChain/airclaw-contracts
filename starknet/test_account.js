// Create and deploy OZ account with specific private key, then deploy escrow
import { RpcProvider, Account, hash, constants } from "starknet";
import fs from "fs";

// Your key
const privateKey = "0x07c4490348c5e8e3b672a932b2ea973de280823e4537e6f1f5453514e3ded8a6";
const rpcUrl = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_10/a0CQ0YnVGtptgWQBGvSXW";

// Read contracts
const contractJson = JSON.parse(fs.readFileSync("./target/dev/airclaw_starknet_escrow.contract_class.json", "utf8"));
const compiledJson = JSON.parse(fs.readFileSync("./target/dev/airclaw_starknet_escrow.compiled_contract_class.json", "utf8"));

// OZ account class hash (Sepolia)
const ACCOUNT_CLASS_HASH = "0x058d96c9646b40457ff4004ae10c03bb9cb92a6645ce4164dab3a76432420c2c";

async function run() {
  console.log("Connecting to RPC...");
  const provider = new RpcProvider({ nodeUrl: rpcUrl, chainId: constants.StarknetChainId.SEPOLIA });
  
  console.log("Creating account with your key...");
  const account = new Account({
    provider,
    address: "0x0",  // Will be computed
    signer: privateKey
  });
  
  // Get the computed address
  const address = account.address;
  console.log("Account address:", address);
  
  // Check if deployed
  console.log("Checking if account is deployed...");
  try {
    const code = await provider.getCode(address);
    console.log("Code length:", code.length);
    if (code.length > 0) {
      console.log("Account already deployed!");
    } else {
      console.log("Account not deployed yet - need to deploy OZ account first");
    }
  } catch (e) {
    console.log("Account check error:", e.message);
  }
}

run().catch(console.error);
