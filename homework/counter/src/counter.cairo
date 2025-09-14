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

    /// Set counter to specific value
    fn set_counter(ref self: TContractState, newValue: u32);

    ///reset counter
    fn reset(ref self: TContractState);
}

/// Counter contract for managing a simple counter value.
#[starknet::contract]
mod Counter {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::event::EventEmitter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterChanged: CounterChanged,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterChanged {
        pub caller: ContractAddress,
        pub old: u32,
        pub new: u32,
        pub reason: ChangeReason,
    }

    #[derive(Drop, Copy, Serde)]
    enum ChangeReason {
        Increase,
        Decrease,
        Reset,
        Set,
    }

    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, owner: ContractAddress) {
        self.counter.write(initial_value);
        self.ownable.initializer(owner);
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
            let newValue = current + 1;
            self.counter.write(newValue);
            let event: CounterChanged = CounterChanged {
                caller: get_caller_address(),
                old: current,
                new: newValue,
                reason: ChangeReason::Increase,
            };
            self.emit(event);
        }

        /// Decrements the counter by 1.
        /// Panics if the counter is already at 0 to prevent underflow.
        fn decrement(ref self: ContractState) {
            let current = self.counter.read();
            assert(current > 0, 'Counter would underflow');
            let newValue = current - 1;
            self.counter.write(newValue);
            let event: CounterChanged = CounterChanged {
                caller: get_caller_address(),
                old: current,
                new: newValue,
                reason: ChangeReason::Decrease,
            };
            self.emit(event);
        }

        /// Set counter to specific value
        /// only owner can call
        fn set_counter(ref self: ContractState, newValue: u32) {
            self.ownable.assert_only_owner();

            let current = self.counter.read();
            self.counter.write(newValue);
            let event: CounterChanged = CounterChanged {
                caller: get_caller_address(),
                old: current,
                new: newValue,
                reason: ChangeReason::Set,
            };
            self.emit(event);
        }

        /// Reset counter to zero
        /// Pay 1 STRK to reset
        fn reset(ref self: ContractState) {
            let payment_amount: u256 = 1000000000000000000;
            let stark_contract: ContractAddress =
                0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
                .try_into()
                .unwrap();
            let caller = get_caller_address();
            let contract = get_contract_address();
            let dispatcher = IERC20Dispatcher { contract_address: stark_contract };
            let balance = dispatcher.balance_of(caller);
            assert!(balance >= payment_amount, "User does not have balance");

            let allowance = dispatcher.allowance(caller, contract);
            assert!(allowance >= payment_amount, "Contract is not allowed to spend enough STRK");

            let owner = self.ownable.owner();
            let success = dispatcher.transfer_from(caller, owner, payment_amount);
            assert!(success, "Transfer of STRK failed.")

            let current = self.counter.read();

            let newValue = 0;
            self.counter.write(newValue);
            let event: CounterChanged = CounterChanged {
                caller: get_caller_address(),
                old: current,
                new: newValue,
                reason: ChangeReason::Reset,
            };
            self.emit(event);
        }
    }
}
