/// Interface representing the Counter contract.
/// This interface allows incrementing, decrementing, and retrieving the counter value.
#[starknet::interface]
pub trait ICounter<TContractState> {
    /// Returns the current value of the counter.
    fn get_counter(self: @TContractState) -> u32;
    
    /// Increments the counter by 1.
    fn increment(ref self: TContractState);
    
    /// Decrements the counter by 1.
    fn decrement(ref self: TContractState);
}

/// Counter contract for managing a simple counter value.
#[starknet::contract]
mod Counter {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32) {
        self.counter.write(initial_value);
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        /// Returns the current value of the counter.
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        /// Increments the counter by 1.
        fn increment(ref self: ContractState) {
            let current = self.counter.read();
            self.counter.write(current + 1);
        }

        /// Decrements the counter by 1.
        /// Panics if the counter is already at 0 to prevent underflow.
        fn decrement(ref self: ContractState) {
            let current = self.counter.read();
            assert(current > 0, 'Counter would underflow');
            self.counter.write(current - 1);
        }
    }
}