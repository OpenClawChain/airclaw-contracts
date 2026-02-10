// Tests for Simplified Starknet Cairo Escrow Contract
// Tests the simplified flow where job metadata is in API/DB

use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};

use escrow::escrow::{Escrow, Escrow::ContractState};
use escrow::interfaces::{EscrowState, EscrowCreated, EscrowAccepted, WorkSubmitted, EscrowApproved};

use openzeppelin::mocks::erc20mock::{ERC20Mock, ERC20Mock::ContractState as ERC20State};

// Helper function to deploy ERC20 mock
fn deploy_erc20() -> ContractAddress:
    let mut calldata = ArrayTrait::new()
    let (erc20_address, _) = deploy_syscall(
        ERC20Mock::TEST_CLASS_HASH,
        0,
        calldata.span(),
        true
    ).unwrap()
    erc20_address
end

// Helper function to deploy escrow contract
fn deploy_escrow(owner: ContractAddress) -> ContractAddress:
    let mut calldata = ArrayTrait::new()
    let mut serialize = ArrayTrait::new()
    serde::Serde::serialize(@owner, ref serialize)
    
    let (escrow_address, _) = deploy_syscall(
        Escrow::TEST_CLASS_HASH,
        0,
        serialize.span(),
        true
    ).unwrap()
end

#[test    escrow_address
]
#[available_gas(2000000)]
fn test_create_escrow():
    let owner: ContractAddress = contract_address_const::<0x123>()
    let creator: ContractAddress = contract_address_const::<0x456>()
    
    # Set up contracts
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Set up ERC20 for creator
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    let job_id = 'test_job_1'
    let amount = 1000_u256
    
    # Create escrow
    let mut contract_state = Escrow::unsafe_new_contract_state()
    Escrow::create_escrow(ref contract_state, job_id, token_address, amount)
    
    # Verify escrow was created
    let state = Escrow::get_escrow_state(@contract_state, job_id)
    assert(state == EscrowState::Created, 'Escrow should be in Created state')
end

#[test]
#[available_gas(3000000)]
fn test_accept_escrow():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    # Set up contracts
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Set up ERC20 for creator
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref ercrow_state, escrow_address, 1000)
    
    # Create escrow
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'test_job_2'
    let amount = 500_u256
    Escrow::create_escrow(ref escrow_state, job_id, token_address, amount)
    
    # Accept escrow (assign worker)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    # Verify state changed to InProgress
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::InProgress, 'Escrow should be InProgress')
end

#[test]
#[available_gas(5000000)]
fn test_full_escrow_flow_approve():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    # Set up contracts
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Setup: Give creator tokens and approve
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    # Step 1: Creator creates escrow
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'full_flow_job'
    let amount = 1000_u256
    Escrow::create_escrow(ref escrow_state, job_id, token_address, amount)
    
    # Verify Created
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::Created, 'Should be Created')
    
    # Step 2: Creator assigns worker
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    # Verify InProgress
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::InProgress, 'Should be InProgress')
    
    # Step 3: Worker submits work
    set_contract_address(worker)
    Escrow::submit_work(ref escrow_state, job_id)
    
    # Verify Submitted
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::Submitted, 'Should be Submitted')
    
    # Step 4: Creator approves - funds released to worker
    set_contract_address(creator)
    Escrow::approve(ref escrow_state, job_id)
    
    # Verify Approved
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::Approved, 'Should be Approved')
end

#[test]
#[available_gas(5000000)]
fn test_full_escrow_flow_reject():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    # Set up contracts
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Setup tokens
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    # Full flow up to Submitted
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'reject_job'
    let amount = 800_u256
    Escrow::create_escrow(ref escrow_state, job_id, token_address, amount)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    # Worker submits work
    set_contract_address(worker)
    Escrow::submit_work(ref escrow_state, job_id)
    
    # Creator rejects - funds refunded to creator
    set_contract_address(creator)
    Escrow::reject(ref escrow_state, job_id)
    
    # Verify Rejected
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::Rejected, 'Should be Rejected')
end

#[test]
#[available_gas(3000000)]
fn test_refund_early_cancel():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    
    # Set up contracts
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Setup tokens
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 500)
    ERC20Mock::approve(ref erc20_state, escrow_address, 500)
    
    # Create escrow
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'refund_job'
    let amount = 300_u256
    Escrow::create_escrow(ref escrow_state, job_id, token_address, amount)
    
    # Refund - early cancel
    Escrow::refund(ref escrow_state, job_id)
    
    # Verify Refunded
    let state = Escrow::get_escrow_state(@escrow_state, job_id)
    assert(state == EscrowState::Refunded, 'Should be Refunded')
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Escrow already exists',))]
fn test_duplicate_escrow():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 2000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 2000)
    
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'duplicate_job'
    
    # Create escrow first time
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
    
    # Try to create again - should panic
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Must be in Created state',))]
fn test_accept_before_create():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    
    set_contract_address(creator)
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    
    # Try to accept non-existent escrow
    Escrow::accept_escrow(ref escrow_state, 'nonexistent', worker)
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Only creator can assign worker',))]
fn test_non_creator_assign_worker():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let other: ContractAddress = contract_address_const::<0x999>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Create escrow as creator
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'test_job'
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
    
    # Try to assign worker as non-creator
    set_contract_address(other)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Only worker can submit',))]
fn test_non_worker_submit():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    let other: ContractAddress = contract_address_const::<0x999>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Create and accept escrow
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'test_job'
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    # Try to submit as non-worker
    set_contract_address(other)
    Escrow::submit_work(ref escrow_state, job_id)
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Must be Submitted',))]
fn test_approve_before_submit():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Create and accept escrow
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'test_job'
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    # Try to approve before submit - should panic
    Escrow::approve(ref escrow_state, job_id)
end

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Cannot refund in current state',))]
fn test_refund_after_submit():
    let owner: ContractAddress = contract_address_const::<0x100>()
    let creator: ContractAddress = contract_address_const::<0x200>()
    let worker: ContractAddress = contract_address_const::<0x300>()
    
    set_contract_address(owner)
    let escrow_address = deploy_escrow(owner)
    let token_address = deploy_erc20()
    
    # Create, accept, and submit
    set_contract_address(creator)
    let mut erc20_state = ERC20Mock::unsafe_new_contract_state()
    ERC20Mock::mint(ref erc20_state, creator, 1000)
    ERC20Mock::approve(ref erc20_state, escrow_address, 1000)
    
    let mut escrow_state = Escrow::unsafe_new_contract_state()
    let job_id = 'test_job'
    Escrow::create_escrow(ref escrow_state, job_id, token_address, 1000)
    Escrow::accept_escrow(ref escrow_state, job_id, worker)
    
    set_contract_address(worker)
    Escrow::submit_work(ref escrow_state, job_id)
    
    # Try to refund after submit - should panic
    set_contract_address(creator)
    Escrow::refund(ref escrow_state, job_id)
end
