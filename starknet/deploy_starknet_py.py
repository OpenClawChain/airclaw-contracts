#!/usr/bin/env python3
"""
Deploy escrow contract using starknet-py with OpenZeppelin account.
"""
import asyncio
import json
from starknet_py.net.account.account import Account
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.models import StarknetChainId
from starknet_py.key_pair import KeyPair
from starknet_py.contract import Contract

# Configuration
ACCOUNT_ADDRESS = "0x02eb0b878df018f7b9f722b7af6496f084b246597014d2886332ac2945431bf8"
OWNER_PRIVATE_KEY = 0x03750e5456f17426a87f70fbd6f2e47a82d95369da7b3cfe4605f79e42108821
OWNER_PUBLIC_KEY = 0x075b450f2192f7da54f50687c6f07821ee1ec8bc0f79fbf9b0ed56c217e99deb
RPC_URL = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_10/a0CQ0YnVGtptgWQBGvSXW"

# Contract paths
CONTRACT_JSON = "/Users/peterclaw/.openclaw/workspace/airclaw-contracts/starknet/target/dev/airclaw_starknet_escrow.contract_class.json"
COMPILED_JSON = "/Users/peterclaw/.openclaw/workspace/airclaw-contracts/starknet/target/dev/airclaw_starknet_escrow.compiled_contract_class.json"

async def main():
    print("Connecting to Starknet Sepolia...")
    
    # Create client
    client = FullNodeClient(RPC_URL, chain=StarknetChainId.SEPOLIA)
    
    # Create account - use KeyPair derived from owner keys
    key_pair = KeyPair.from_private_key(OWNER_PRIVATE_KEY)
    print(f"Key pair public key: {hex(key_pair.public_key)}")
    print(f"Expected public key: {hex(OWNER_PUBLIC_KEY)}")
    
    account = Account(
        client=client,
        address=ACCOUNT_ADDRESS,
        key_pair=key_pair,
        chain=StarknetChainId.SEPOLIA
    )
    print(f"Account: {ACCOUNT_ADDRESS}")
    
    # Get nonce
    nonce = await account.get_nonce()
    print(f"Nonce: {nonce}")
    
    # Load contract
    with open(CONTRACT_JSON) as f:
        contract_data = json.load(f)
    
    with open(COMPILED_JSON) as f:
        compiled_data = json.load(f)
    
    # Declare
    print("\nDeclaring contract...")
    try:
        declare_result = await account.declare(
            contract_class=contract_data,
            compiled_contract_class=compiled_data,
            max_fee=0  # Auto-estimate
        )
        print(f"Declared! Class hash: {declare_result.class_hash}")
        print(f"Transaction hash: {declare_result.transaction_hash}")
        
        # Wait for transaction
        print("Waiting for confirmation...")
        await client.wait_for_tx(declare_result.transaction_hash)
        print("Declare confirmed!")
        
        # Deploy
        print("\nDeploying contract...")
        deploy_result = await account.deploy_contract(
            class_hash=declare_result.class_hash,
            constructor_calldata=[int(ACCOUNT_ADDRESS, 16)],
            max_fee=0  # Auto-estimate
        )
        print(f"Deployed! Address: {deploy_result.contract_address}")
        print(f"Transaction hash: {deploy_result.transaction_hash}")
        
        # Save result
        result = {
            "address": hex(deploy_result.contract_address),
            "tx_hash": hex(deploy_result.transaction_hash),
            "class_hash": hex(declare_result.class_hash),
            "deployer": ACCOUNT_ADDRESS
        }
        with open("deployment-info.json", "w") as f:
            json.dump(result, f, indent=2)
        print("\nSaved to deployment-info.json")
        
    except Exception as e:
        print(f"Error: {e}")
        if hasattr(e, 'response'):
            print(f"Response: {e.response}")

if __name__ == "__main__":
    asyncio.run(main())
