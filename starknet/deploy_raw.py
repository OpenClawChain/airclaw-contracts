#!/usr/bin/env python3
"""
Deploy escrow contract to Starknet Sepolia using raw RPC calls.
"""
import json
import requests
from Crypto.Hash import keccak

# Configuration
ACCOUNT_ADDRESS = "0x02eb0b878df018f7b9f722b7af6496f084b246597014d2886332ac2945431bf8"
PRIVATE_KEY = 0x07c4490348c5e8e3b672a932b2ea973de280823e4537e6f1f5453514e3ded8a6
RPC_URL = "https://starknet-sepolia-rpc.publicnode.com"

# Contract paths
CONTRACT_JSON = "/Users/peterclaw/.openclaw/workspace/airclaw-contracts/starknet/target/dev/airclaw_starknet_escrow.contract_class.json"
COMPILED_JSON = "/Users/peterclaw/.openclaw/workspace/airclaw-contracts/starknet/target/dev/airclaw_starknet_escrow.compiled_contract_class.json"

# Class hashes (pre-computed)
CLASS_HASH = "0x3163e3de87f052ab399d3820c4ab35331de34b268cb4590a6b9c59b8f3fc219"
COMPILED_CLASS_HASH = "0x332c0ea002d60bbe2d82ea0f5563c9dabcd1e5480aa6ab1aef37c3835723e1b"

def rpc(method, params=None):
    """Make an RPC call."""
    resp = requests.post(RPC_URL, json={
        "jsonrpc": "2.0",
        "id": 1,
        "method": method,
        "params": params or {}
    }, timeout=60)
    resp.raise_for_status()
    return resp.json()

def get_nonce():
    """Get account nonce."""
    result = rpc("starknet_getNonce", {
        "contract_address": ACCOUNT_ADDRESS,
        "block_id": "latest"
    })
    return int(result['result'], 16)

def get_chain_id():
    """Get chain ID."""
    result = rpc("starknet_chainId")
    return result['result']

def keccak256(data):
    """Compute keccak256 hash."""
    k = keccak.new(digest_bits=256)
    k.update(data)
    return k.hexdigest()

def get_tip_hash():
    """Compute transaction tip hash."""
    # Simplified - returns 0 for now
    return "0x0"

def compute_transaction_hash(request, chain_id):
    """Compute the transaction hash (simplified)."""
    # This is complex - for now, we use a placeholder
    return "0x0"

def submit_declare():
    """Submit a DECLARE transaction."""
    # Load contracts
    with open(CONTRACT_JSON) as f:
        contract_data = json.load(f)
    
    nonce = get_nonce()
    chain_id = get_chain_id()
    
    print(f"Chain ID: {chain_id}")
    print(f"Nonce: {nonce}")
    print(f"Class Hash: {CLASS_HASH}")
    
    # Build DECLARE V3 request
    request = {
        "type": "DECLARE",
        "sender_address": ACCOUNT_ADDRESS,
        "nonce": hex(nonce),
        "version": "0x3",  # V3
        "contract_class": {
            "sierra_program": contract_data['sierra_program'],
            "contract_class_version": contract_data.get('contract_class_version', '0.1.0'),
            "entry_points_by_type": contract_data['entry_points_by_type'],
            "abi": contract_data['abi']
        },
        "compiled_class_hash": COMPILED_CLASS_HASH,
        "resource_bounds": {
            "l1_gas": {
                "max_amount": "0x186A0",  # ~100k gas units
                "max_price_per_unit": "0x5AF3107A4000"  # ~0.01 ETH per gas unit
            },
            "l2_gas": {
                "max_amount": "0x0",
                "max_price_per_unit": "0x0"
            }
        }
    }
    
    print("\nSubmitting DECLARE transaction...")
    print(f"Request: {json.dumps(request, indent=2)[:500]}...")
    
    try:
        result = rpc("starknet_addDeclareTransaction", request)
        print(f"Result: {json.dumps(result, indent=2)}")
        
        if 'result' in result:
            tx_hash = result['result']['transaction_hash']
            print(f"\nTransaction submitted!")
            print(f"Transaction Hash: {tx_hash}")
            return tx_hash
    except Exception as e:
        print(f"Error: {e}")
        if hasattr(e, 'response'):
            print(f"Response: {e.response.text}")
        return None

if __name__ == "__main__":
    submit_declare()
