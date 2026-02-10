#!/usr/bin/env python3
"""
Deploy escrow contract using Python raw RPC calls.
Uses starkware.crypto for signing.
"""
import json
import requests
import time
from Crypto.Hash import keccak

# Configuration
ACCOUNT_ADDRESS = "0x02eb0b878df018f7b9f722b7af6496f084b246597014d2886332ac2945431bf8"
PRIVATE_KEY = 0x03750e5456f17426a87f70fbd6f2e47a82d95369da7b3cfe4605f79e42108821
RPC_URL = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_10/a0CQ0YnVGtptgWQBGvSXW"

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

def starknet_keccak256(data):
    """Compute Starknet keccak256 hash."""
    k = keccak.new(digest_bits=256)
    k.update(data)
    return k.hexdigest()

def pedersen_hash(a, b):
    """Pedersen hash (placeholder - needs starkware library)."""
    # This is complex - we'll skip for now
    return "0x0"

def compute_hash_on_web(request, chain_id):
    """Compute transaction hash using RPC."""
    result = rpc("starknet_computeTransactionHash", {
        "tx": request,
        "chain_id": chain_id
    })
    return result['result']

def get_signature(tx_hash, private_key):
    """Get signature for a transaction hash (placeholder)."""
    # Starknet signing is different - use RPC
    result = rpc("starknet_signTransaction", {
        "tx": {
            "type": "DECLARE",
            "sender_address": ACCOUNT_ADDRESS,
            "nonce": "0x2",
            "version": "0x3"
        },
        "private_key": hex(private_key)
    })
    return result['result']

def submit_declare():
    """Submit a DECLARE V3 transaction."""
    with open(CONTRACT_JSON) as f:
        contract_data = json.load(f)
    
    nonce = get_nonce()
    chain_id = get_chain_id()
    
    print(f"Chain ID: {chain_id}")
    print(f"Nonce: {nonce}")
    
    # Build DECLARE V3 request
    request = {
        "type": "DECLARE",
        "sender_address": ACCOUNT_ADDRESS,
        "nonce": hex(nonce),
        "version": "0x3",
        "contract_class": {
            "sierra_program": contract_data['sierra_program'],
            "contract_class_version": contract_data.get('contract_class_version', '0.1.0'),
            "entry_points_by_type": contract_data['entry_points_by_type'],
            "abi": contract_data['abi']
        },
        "compiled_class_hash": COMPILED_CLASS_HASH,
        "resource_bounds": {
            "l1_gas": {
                "max_amount": "0x186A0",
                "max_price_per_unit": "0x5AF3107A4000"
            },
            "l2_gas": {
                "max_amount": "0x0",
                "max_price_per_unit": "0x0"
            }
        }
    }
    
    # Get transaction hash from RPC
    print("Computing transaction hash...")
    try:
        tx_hash = compute_hash_on_web(request, chain_id)
        print(f"Transaction hash: {tx_hash}")
        
        # Get signature
        print("Getting signature...")
        sig_result = rpc("starknet_signTransaction", {
            "tx": request,
            "private_key": hex(PRIVATE_KEY)
        })
        signature = sig_result['result']
        print(f"Signature: {signature}")
        
        # Submit
        print("Submitting DECLARE V3...")
        result = rpc("starknet_addDeclareTransaction", {
            "declare_transaction": {
                **request,
                "signature": signature
            }
        })
        print(f"Result: {json.dumps(result, indent=2)}")
        
        if 'result' in result:
            return result['result']['transaction_hash']
            
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    submit_declare()
