// Simple Escrow Contract for Starknet

#[starknet::contract]
#[feature("deprecated_legacy_map")]
mod escrow {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::syscalls::call_contract_syscall;
    use starknet::SyscallResultTrait;

    #[storage]
    struct Storage {
        states: LegacyMap<felt252, felt252>,
        creators: LegacyMap<felt252, ContractAddress>,
        workers: LegacyMap<felt252, ContractAddress>,
        tokens: LegacyMap<felt252, ContractAddress>,
        amounts: LegacyMap<felt252, u256>,
        created_at: LegacyMap<felt252, u64>,
    }

    // State constants
    const STATE_NONE: felt252 = 0;
    const STATE_CREATED: felt252 = 1;
    const STATE_IN_PROGRESS: felt252 = 2;
    const STATE_SUBMITTED: felt252 = 3;
    const STATE_APPROVED: felt252 = 4;
    const STATE_REJECTED: felt252 = 5;
    const STATE_REFUNDED: felt252 = 6;

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {}

    #[external(v0)]
    fn create_escrow(
        ref self: ContractState, 
        job_id: felt252, 
        token: ContractAddress, 
        amount: u256
    ) {
        let caller = get_caller_address();
        assert(amount > 0_u256, 'Amount must be positive');
        
        let current_state = self.states.read(job_id);
        assert(current_state == STATE_NONE, 'Escrow already exists');
        
        let self_address = get_contract_address();
        
        let result = self._transfer_from(token, caller, self_address, amount);
        assert(result, 'Transfer failed');

        self.states.write(job_id, STATE_CREATED);
        self.creators.write(job_id, caller);
        self.tokens.write(job_id, token);
        self.amounts.write(job_id, amount);
        self.created_at.write(job_id, starknet::get_block_timestamp());
    }

    #[external(v0)]
    fn accept_escrow(ref self: ContractState, job_id: felt252, worker: ContractAddress) {
        let caller = get_caller_address();
        assert(self.states.read(job_id) == STATE_CREATED, 'Must be Created');
        assert(caller == self.creators.read(job_id), 'Only creator');
        
        self.workers.write(job_id, worker);
        self.states.write(job_id, STATE_IN_PROGRESS);
    }

    #[external(v0)]
    fn submit_work(ref self: ContractState, job_id: felt252) {
        let caller = get_caller_address();
        assert(self.states.read(job_id) == STATE_IN_PROGRESS, 'Must be InProgress');
        assert(caller == self.workers.read(job_id), 'Only worker');
        
        self.states.write(job_id, STATE_SUBMITTED);
    }

    #[external(v0)]
    fn approve(ref self: ContractState, job_id: felt252) {
        let caller = get_caller_address();
        assert(self.states.read(job_id) == STATE_SUBMITTED, 'Must be Submitted');
        assert(caller == self.creators.read(job_id), 'Only creator');
        
        let worker = self.workers.read(job_id);
        let token = self.tokens.read(job_id);
        let amount = self.amounts.read(job_id);
        
        let result = self._transfer(token, worker, amount);
        assert(result, 'Transfer failed');
        
        self.states.write(job_id, STATE_APPROVED);
    }

    #[external(v0)]
    fn reject(ref self: ContractState, job_id: felt252) {
        let caller = get_caller_address();
        assert(self.states.read(job_id) == STATE_SUBMITTED, 'Must be Submitted');
        assert(caller == self.creators.read(job_id), 'Only creator');
        
        let creator = self.creators.read(job_id);
        let token = self.tokens.read(job_id);
        let amount = self.amounts.read(job_id);
        
        let result = self._transfer(token, creator, amount);
        assert(result, 'Transfer failed');
        
        self.states.write(job_id, STATE_REJECTED);
    }

    #[external(v0)]
    fn refund(ref self: ContractState, job_id: felt252) {
        let caller = get_caller_address();
        assert(caller == self.creators.read(job_id), 'Only creator');
        
        let current_state = self.states.read(job_id);
        let can_refund = (current_state == STATE_CREATED) | (current_state == STATE_IN_PROGRESS);
        assert(can_refund, 'Cannot refund');
        
        let creator = self.creators.read(job_id);
        let token = self.tokens.read(job_id);
        let amount = self.amounts.read(job_id);
        
        let result = self._transfer(token, creator, amount);
        assert(result, 'Transfer failed');
        
        self.states.write(job_id, STATE_REFUNDED);
    }

    #[external(v0)]
    fn get_state(self: @ContractState, job_id: felt252) -> felt252 {
        self.states.read(job_id)
    }

    #[external(v0)]
    fn get_details(
        self: @ContractState, 
        job_id: felt252
    ) -> (ContractAddress, ContractAddress, ContractAddress, u256, felt252) {
        (
            self.creators.read(job_id),
            self.workers.read(job_id),
            self.tokens.read(job_id),
            self.amounts.read(job_id),
            self.states.read(job_id)
        )
    }

    // Internal helpers using raw calls
    #[generate_trait]
    impl InternalImpl of Internal {
        fn _transfer(
            ref self: ContractState, 
            token: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            let mut calldata = array![];
            Serde::serialize(@to, ref calldata);
            Serde::serialize(@amount, ref calldata);
            
            let mut result_span = call_contract_syscall(
                token,
                selector!("transfer"),
                calldata.span()
            ).unwrap_syscall();
            
            let success_felt = *result_span.pop_front().unwrap();
            let success = success_felt != 0;
            success
        }
        
        fn _transfer_from(
            ref self: ContractState, 
            token: ContractAddress, 
            from: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            let mut calldata = array![];
            Serde::serialize(@from, ref calldata);
            Serde::serialize(@to, ref calldata);
            Serde::serialize(@amount, ref calldata);
            
            let mut result_span = call_contract_syscall(
                token,
                selector!("transfer_from"),
                calldata.span()
            ).unwrap_syscall();
            
            let success_felt = *result_span.pop_front().unwrap();
            let success = success_felt != 0;
            success
        }
    }
}
