// Simplified Escrow Interface for Starknet Cairo
// Key Change: Job metadata stored in API/DB. Contract only handles escrow state + funds.

use starknet::ContractAddress;

// Escrow state enum (for API reference)
enum EscrowState {
    None,
    Created,
    InProgress,
    Submitted,
    Approved,
    Rejected,
    Refunded,
}

// Event definitions (shared with contract)
#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct EscrowCreated {
    job_id: felt252,
    creator: ContractAddress,
    token: ContractAddress,
    amount: u256,
}

#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct EscrowAccepted {
    job_id: felt252,
    worker: ContractAddress,
}

#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct WorkSubmitted {
    job_id: felt252,
}

#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct EscrowApproved {
    job_id: felt252,
    worker: ContractAddress,
    amount: u256,
}

#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct EscrowRejected {
    job_id: felt252,
    creator: ContractAddress,
    amount: u256,
}

#[derive(Drop, Debug, PartialEq, starknet::Event)]
struct EscrowRefunded {
    job_id: felt252,
    creator: ContractAddress,
    amount: u256,
}
