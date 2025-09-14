use counter::counter::{ICounterDispatcher, ICounterDispatcherTrait};
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

/// Deploy the counter contract with an initial value
fn deploy_counter(initial_value: u32) -> ContractAddress {
    let contract = declare("Counter").unwrap().contract_class();
    let constructor_calldata = array![initial_value.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_constructor_with_zero() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should be initialized to 0");
}

#[test]
fn test_constructor_with_initial_value() {
    let initial_value = 42_u32;
    let contract_address = deploy_counter(initial_value);
    let dispatcher = ICounterDispatcher { contract_address };
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, initial_value, "Counter should be initialized to {}", initial_value);
}

#[test]
fn test_increment_from_zero() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.increment();
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 1, "Counter should be 1 after increment from 0");
}

#[test]
fn test_increment_multiple_times() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.increment();
    dispatcher.increment();
    dispatcher.increment();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 3, "Counter should be 3 after three increments");
}

#[test]
fn test_decrement_from_positive() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.decrement();
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 9, "Counter should be 9 after decrement from 10");
}

#[test]
fn test_decrement_multiple_times() {
    let contract_address = deploy_counter(5);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.decrement();
    dispatcher.decrement();
    dispatcher.decrement();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 2, "Counter should be 2 after three decrements from 5");
}

#[test]
#[should_panic(expected: ('Counter would underflow',))]
fn test_decrement_underflow_from_zero() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.decrement(); // This should panic
}

#[test]
#[should_panic(expected: ('Counter would underflow',))]
fn test_decrement_underflow_after_reaching_zero() {
    let contract_address = deploy_counter(1);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.decrement(); // Counter becomes 0
    dispatcher.decrement(); // This should panic
}

#[test]
fn test_mixed_operations() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.increment();    // 11
    dispatcher.increment();    // 12
    dispatcher.decrement();    // 11
    dispatcher.increment();    // 12
    dispatcher.decrement();    // 11
    dispatcher.decrement();    // 10
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 10, "Counter should be 10 after mixed operations");
}

#[test]
fn test_large_number_operations() {
    let initial: u32 = 1000000;
    let contract_address = deploy_counter(initial);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Perform many increments
    let mut i: u32 = 0;
    loop {
        if i >= 100 {
            break;
        }
        dispatcher.increment();
        i += 1;
    };
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, initial + 100, "Counter should handle large numbers correctly");
}

#[test]
fn test_get_counter_multiple_calls() {
    let contract_address = deploy_counter(42);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Call get_counter multiple times to ensure it doesn't modify state
    let first_call = dispatcher.get_counter();
    let second_call = dispatcher.get_counter();
    let third_call = dispatcher.get_counter();
    
    assert_eq!(first_call, 42, "First call should return 42");
    assert_eq!(second_call, 42, "Second call should return 42");
    assert_eq!(third_call, 42, "Third call should return 42");
}