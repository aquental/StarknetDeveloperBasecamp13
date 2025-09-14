use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use counter::counter::ICounterSafeDispatcher;
use counter::counter::ICounterSafeDispatcherTrait;
use counter::counter::ICounterDispatcher;
use counter::counter::ICounterDispatcherTrait;

fn deploy_counter_contract(initial_value: u32) -> ContractAddress {
    let contract = declare("Counter").unwrap().contract_class();
    let constructor_calldata = array![initial_value.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_counter_increment() {
    let contract_address = deploy_counter_contract(0);

    let dispatcher = ICounterDispatcher { contract_address };

    let counter_before = dispatcher.get_counter();
    assert(counter_before == 0, 'Invalid initial counter');

    dispatcher.increment();

    let counter_after = dispatcher.get_counter();
    assert(counter_after == 1, 'Counter should be 1');
}

#[test]
fn test_counter_decrement() {
    let contract_address = deploy_counter_contract(5);

    let dispatcher = ICounterDispatcher { contract_address };

    let counter_before = dispatcher.get_counter();
    assert(counter_before == 5, 'Invalid initial counter');

    dispatcher.decrement();

    let counter_after = dispatcher.get_counter();
    assert(counter_after == 4, 'Counter should be 4');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_decrement_below_zero() {
    let contract_address = deploy_counter_contract(0);

    let safe_dispatcher = ICounterSafeDispatcher { contract_address };

    let counter_before = safe_dispatcher.get_counter().unwrap();
    assert(counter_before == 0, 'Invalid initial counter');

    match safe_dispatcher.decrement() {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(panic_data.at(0) == @'Counter would underflow', 'Wrong panic message');
        }
    };
}

#[test]
fn test_set_counter_integration() {
    let contract_address = deploy_counter_contract(10);
    let dispatcher = ICounterDispatcher { contract_address };

    // Verify initial value
    assert(dispatcher.get_counter() == 10, 'Invalid initial value');

    // Set to new value
    dispatcher.set_counter(42);
    assert(dispatcher.get_counter() == 42, 'Counter should be 42');

    // Set to zero
    dispatcher.set_counter(0);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');

    // Set to large value
    dispatcher.set_counter(1000000);
    assert(dispatcher.get_counter() == 1000000, 'Counter should be 1000000');
}

#[test]
fn test_reset_integration() {
    let contract_address = deploy_counter_contract(999);
    let dispatcher = ICounterDispatcher { contract_address };

    // Verify initial value
    assert(dispatcher.get_counter() == 999, 'Invalid initial value');

    // Reset counter
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 after reset');

    // Increment after reset
    dispatcher.increment();
    assert(dispatcher.get_counter() == 1, 'Counter should be 1');

    // Reset again
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 again');
}

#[test]
fn test_combined_operations_integration() {
    let contract_address = deploy_counter_contract(50);
    let dispatcher = ICounterDispatcher { contract_address };

    // Initial check
    assert(dispatcher.get_counter() == 50, 'Initial value should be 50');

    // Use set_counter
    dispatcher.set_counter(75);
    assert(dispatcher.get_counter() == 75, 'Counter should be 75');

    // Increment
    dispatcher.increment();
    assert(dispatcher.get_counter() == 76, 'Counter should be 76');

    // Reset
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');

    // Set to new value after reset
    dispatcher.set_counter(10);
    assert(dispatcher.get_counter() == 10, 'Counter should be 10');

    // Decrement
    dispatcher.decrement();
    assert(dispatcher.get_counter() == 9, 'Counter should be 9');
}

#[test]
#[feature("safe_dispatcher")]
fn test_reset_then_decrement_safe() {
    let contract_address = deploy_counter_contract(50);
    let safe_dispatcher = ICounterSafeDispatcher { contract_address };

    // Reset counter
    let _ = safe_dispatcher.reset();
    assert(safe_dispatcher.get_counter().unwrap() == 0, 'Should be 0 after reset');

    // Try to decrement from 0 (should panic)
    match safe_dispatcher.decrement() {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(panic_data.at(0) == @'Counter would underflow', 'Wrong panic message');
        }
    };
}
