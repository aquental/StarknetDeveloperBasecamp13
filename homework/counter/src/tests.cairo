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

// ==================== Tests for set_counter ====================

#[test]
fn test_set_counter_to_zero() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Set counter to 0
    dispatcher.set_counter(0);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should be 0 after set_counter(0)");
}

#[test]
fn test_set_counter_to_specific_value() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Set counter to 999
    dispatcher.set_counter(999);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 999, "Counter should be 999 after set_counter(999)");
}

#[test]
fn test_set_counter_multiple_times() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.set_counter(10);
    assert_eq!(dispatcher.get_counter(), 10, "Counter should be 10");
    
    dispatcher.set_counter(50);
    assert_eq!(dispatcher.get_counter(), 50, "Counter should be 50");
    
    dispatcher.set_counter(25);
    assert_eq!(dispatcher.get_counter(), 25, "Counter should be 25");
}

#[test]
fn test_set_counter_to_max_u32() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    let max_u32: u32 = 4294967295; // 2^32 - 1
    dispatcher.set_counter(max_u32);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, max_u32, "Counter should handle max u32 value");
}

#[test]
fn test_set_counter_then_increment() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.set_counter(50);
    dispatcher.increment();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 51, "Counter should be 51 after set to 50 then increment");
}

#[test]
fn test_set_counter_then_decrement() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.set_counter(50);
    dispatcher.decrement();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 49, "Counter should be 49 after set to 50 then decrement");
}

// ==================== Tests for reset ====================

#[test]
fn test_reset_from_zero() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.reset();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should remain 0 after reset from 0");
}

#[test]
fn test_reset_from_positive_value() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.reset();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should be 0 after reset from 100");
}

#[test]
fn test_reset_after_increments() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.increment(); // 11
    dispatcher.increment(); // 12
    dispatcher.increment(); // 13
    
    dispatcher.reset();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should be 0 after reset");
}

#[test]
fn test_reset_multiple_times() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.reset();
    assert_eq!(dispatcher.get_counter(), 0, "Counter should be 0 after first reset");
    
    dispatcher.increment(); // 1
    dispatcher.increment(); // 2
    
    dispatcher.reset();
    assert_eq!(dispatcher.get_counter(), 0, "Counter should be 0 after second reset");
    
    dispatcher.reset();
    assert_eq!(dispatcher.get_counter(), 0, "Counter should be 0 after third reset");
}

#[test]
fn test_reset_then_increment() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.reset();
    dispatcher.increment();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 1, "Counter should be 1 after reset then increment");
}

#[test]
#[should_panic(expected: ('Counter would underflow',))]
fn test_reset_then_decrement() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.reset();
    dispatcher.decrement(); // Should panic because counter is 0
}

// ==================== Tests for combined operations ====================

#[test]
fn test_combined_set_reset_operations() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    
    dispatcher.set_counter(50);  // Set to 50
    assert_eq!(dispatcher.get_counter(), 50, "Counter should be 50");
    
    dispatcher.reset();          // Reset to 0
    assert_eq!(dispatcher.get_counter(), 0, "Counter should be 0 after reset");
    
    dispatcher.set_counter(25);  // Set to 25
    dispatcher.increment();      // 26
    dispatcher.increment();      // 27
    assert_eq!(dispatcher.get_counter(), 27, "Counter should be 27");
    
    dispatcher.reset();          // Reset to 0
    dispatcher.set_counter(100); // Set to 100
    dispatcher.decrement();      // 99
    assert_eq!(dispatcher.get_counter(), 99, "Counter should be 99");
}

#[test]
fn test_all_operations_together() {
    let contract_address = deploy_counter(20);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Test initial value
    assert_eq!(dispatcher.get_counter(), 20, "Initial value should be 20");
    
    // Test increment
    dispatcher.increment();
    assert_eq!(dispatcher.get_counter(), 21, "Counter should be 21 after increment");
    
    // Test set_counter
    dispatcher.set_counter(100);
    assert_eq!(dispatcher.get_counter(), 100, "Counter should be 100 after set_counter");
    
    // Test decrement
    dispatcher.decrement();
    assert_eq!(dispatcher.get_counter(), 99, "Counter should be 99 after decrement");
    
    // Test reset
    dispatcher.reset();
    assert_eq!(dispatcher.get_counter(), 0, "Counter should be 0 after reset");
    
    // Test operations after reset
    dispatcher.set_counter(5);
    dispatcher.increment();
    dispatcher.increment();
    assert_eq!(dispatcher.get_counter(), 7, "Counter should be 7");
}
