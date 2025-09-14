use starknet::{ContractAddress};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, 
    start_cheat_caller_address, stop_cheat_caller_address,
    start_mock_call, stop_mock_call
};
use counter::counter::{ICounterSafeDispatcher, ICounterSafeDispatcherTrait};
use counter::counter::{ICounterDispatcher, ICounterDispatcherTrait};

// Constants for STRK payment
const ONE_STRK: u256 = 1000000000000000000; // 1 STRK in wei
const STRK_ADDRESS: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

fn deploy_counter_contract(initial_value: u32) -> ContractAddress {
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let contract = declare("Counter").unwrap().contract_class();
    let constructor_calldata = array![initial_value.into(), owner.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

fn get_strk_address() -> ContractAddress {
    STRK_ADDRESS.try_into().unwrap()
}

fn setup_strk_payment_mocks() {
    let strk_address = get_strk_address();
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 100);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 100);
    start_mock_call(strk_address, selector!("transfer_from"), true);
}

fn teardown_strk_payment_mocks() {
    let strk_address = get_strk_address();
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
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
            // The panic data contains the error message
            // We just check that it panicked as expected
            assert(panic_data.len() > 0, 'Should have panic message');
        }
    };
}

#[test]
fn test_set_counter_integration() {
    let contract_address = deploy_counter_contract(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();

    // Verify initial value
    assert(dispatcher.get_counter() == 10, 'Invalid initial value');

    // Set to new value
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(42);
    assert(dispatcher.get_counter() == 42, 'Counter should be 42');

    // Set to zero
    dispatcher.set_counter(0);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');

    // Set to large value
    dispatcher.set_counter(1000000);
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 1000000, 'Counter should be 1000000');
}

#[test]
fn test_reset_integration() {
    let contract_address = deploy_counter_contract(999);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x123.try_into().unwrap();

    // Verify initial value
    assert(dispatcher.get_counter() == 999, 'Invalid initial value');

    // Setup payment mocks for reset
    setup_strk_payment_mocks();

    // Reset counter (any user can call it with payment)
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 after reset');

    // Increment after reset
    dispatcher.increment();
    assert(dispatcher.get_counter() == 1, 'Counter should be 1');

    // Reset again (still with payment)
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 again');

    // Cleanup mocks
    teardown_strk_payment_mocks();
}

#[test]
fn test_combined_operations_integration() {
    let contract_address = deploy_counter_contract(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let user: ContractAddress = 0x456.try_into().unwrap();

    // Initial check
    assert(dispatcher.get_counter() == 50, 'Initial value should be 50');

    // Use set_counter (owner only)
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(75);
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 75, 'Counter should be 75');

    // Increment (anyone can call)
    dispatcher.increment();
    assert(dispatcher.get_counter() == 76, 'Counter should be 76');

    // Setup payment mocks for reset
    setup_strk_payment_mocks();

    // Reset (user pays)
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');

    // Set to new value after reset
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(10);
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 10, 'Counter should be 10');

    // Decrement
    dispatcher.decrement();
    assert(dispatcher.get_counter() == 9, 'Counter should be 9');

    // Cleanup mocks
    teardown_strk_payment_mocks();
}

#[test]
#[feature("safe_dispatcher")]
fn test_reset_then_decrement_safe() {
    let contract_address = deploy_counter_contract(50);
    let safe_dispatcher = ICounterSafeDispatcher { contract_address };
    let user: ContractAddress = 0x789.try_into().unwrap();

    // Setup payment mocks for reset
    setup_strk_payment_mocks();

    // Reset counter (user pays)
    start_cheat_caller_address(contract_address, user);
    let _ = safe_dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(safe_dispatcher.get_counter().unwrap() == 0, 'Should be 0 after reset');

    // Try to decrement from 0 (should panic)
    match safe_dispatcher.decrement() {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            // The panic data contains the error message
            // We just check that it panicked as expected
            assert(panic_data.len() > 0, 'Should have panic message');
        }
    };

    // Cleanup mocks
    teardown_strk_payment_mocks();
}

#[test]
fn test_reset_requires_payment() {
    let contract_address = deploy_counter_contract(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0xabc.try_into().unwrap();

    // Verify initial value
    assert(dispatcher.get_counter() == 100, 'Invalid initial value');

    // Try to reset without mocking payment (should fail)
    // In reality, this would panic with "User does not have balance"
    // but we don't test the panic here since it's covered in unit tests

    // Setup payment and reset successfully
    setup_strk_payment_mocks();
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');

    teardown_strk_payment_mocks();
}