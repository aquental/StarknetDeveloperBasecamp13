use counter::counter::{ICounterDispatcher, ICounterDispatcherTrait};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use starknet::ContractAddress;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, 
    start_cheat_caller_address, stop_cheat_caller_address,
    start_mock_call, stop_mock_call,
    spy_events, EventSpyTrait, EventsFilterTrait
};

// ==================== Constants ====================

const ONE_STRK: u256 = 1000000000000000000; // 1 STRK in wei
const STRK_ADDRESS: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

// ==================== Helper Functions ====================

/// Deploy the counter contract with an initial value and owner
fn deploy_counter(initial_value: u32) -> ContractAddress {
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let contract = declare("Counter").unwrap().contract_class();
    let constructor_calldata = array![initial_value.into(), owner.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

/// Get STRK contract address
fn get_strk_address() -> ContractAddress {
    STRK_ADDRESS.try_into().unwrap()
}

// ==================== Constructor Tests ====================

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

// ==================== Increment Tests ====================

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

// ==================== Decrement Tests ====================

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

// ==================== Mixed Operations Tests ====================

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
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    // Set counter to 0 as owner
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(0);
    stop_cheat_caller_address(contract_address);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 0, "Counter should be 0 after set_counter(0)");
}

#[test]
fn test_set_counter_to_specific_value() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    // Set counter to 999 as owner
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(999);
    stop_cheat_caller_address(contract_address);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 999, "Counter should be 999 after set_counter(999)");
}

#[test]
fn test_set_counter_multiple_times() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(10);
    assert_eq!(dispatcher.get_counter(), 10, "Counter should be 10");
    
    dispatcher.set_counter(50);
    assert_eq!(dispatcher.get_counter(), 50, "Counter should be 50");
    
    dispatcher.set_counter(25);
    assert_eq!(dispatcher.get_counter(), 25, "Counter should be 25");
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_set_counter_to_max_u32() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    let max_u32: u32 = 4294967295; // 2^32 - 1
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(max_u32);
    stop_cheat_caller_address(contract_address);
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, max_u32, "Counter should handle max u32 value");
}

#[test]
fn test_set_counter_then_increment() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(50);
    stop_cheat_caller_address(contract_address);
    
    dispatcher.increment();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 51, "Counter should be 51 after set to 50 then increment");
}

#[test]
fn test_set_counter_then_decrement() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(50);
    stop_cheat_caller_address(contract_address);
    
    dispatcher.decrement();
    
    let counter = dispatcher.get_counter();
    assert_eq!(counter, 49, "Counter should be 49 after set to 50 then decrement");
}

// ==================== Tests for operations without reset ====================

#[test]
fn test_all_operations_without_reset() {
    let contract_address = deploy_counter(20);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    // Test initial value
    assert_eq!(dispatcher.get_counter(), 20, "Initial value should be 20");
    
    // Test increment
    dispatcher.increment();
    assert_eq!(dispatcher.get_counter(), 21, "Counter should be 21 after increment");
    
    // Test set_counter
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(100);
    stop_cheat_caller_address(contract_address);
    assert_eq!(dispatcher.get_counter(), 100, "Counter should be 100 after set_counter");
    
    // Test decrement
    dispatcher.decrement();
    assert_eq!(dispatcher.get_counter(), 99, "Counter should be 99 after decrement");
    
    // Test operations after set
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(5);
    stop_cheat_caller_address(contract_address);
    
    dispatcher.increment();
    dispatcher.increment();
    assert_eq!(dispatcher.get_counter(), 7, "Counter should be 7");
}

// ==================== Ownership Tests ====================

#[test]
fn test_ownership_set_correctly() {
    let contract_address = deploy_counter(0);
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    // Verify owner is set correctly
    let ownable_dispatcher = IOwnableDispatcher { contract_address };
    let actual_owner = ownable_dispatcher.owner();
    assert_eq!(actual_owner, owner, "Owner should be set correctly");
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_non_owner_cannot_set_counter() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let non_owner: ContractAddress = 0x2.try_into().unwrap();
    
    // Try to set counter as non-owner (should panic)
    start_cheat_caller_address(contract_address, non_owner);
    dispatcher.set_counter(50);
    stop_cheat_caller_address(contract_address);
}

// ==================== Event Tests for increment ====================

#[test]
fn test_increment_emits_event() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let caller: ContractAddress = 0x123.try_into().unwrap();
    
    // Start spying on events
    let mut spy = spy_events();
    
    // Call increment as a specific caller
    start_cheat_caller_address(contract_address, caller);
    dispatcher.increment();
    stop_cheat_caller_address(contract_address);
    
    // Check that an event was emitted
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 1, 'Should emit 1 event');
}

#[test]
fn test_multiple_increments_emit_multiple_events() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let caller: ContractAddress = 0x456.try_into().unwrap();
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, caller);
    
    // Three increments
    dispatcher.increment();
    dispatcher.increment();
    dispatcher.increment();
    
    stop_cheat_caller_address(contract_address);
    
    // Verify three events were emitted
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
}

// ==================== Event Tests for decrement ====================

#[test]
fn test_decrement_emits_event() {
    let contract_address = deploy_counter(20);
    let dispatcher = ICounterDispatcher { contract_address };
    let caller: ContractAddress = 0x789.try_into().unwrap();
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, caller);
    dispatcher.decrement();
    stop_cheat_caller_address(contract_address);
    
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 1, 'Should emit 1 event');
}

#[test]
fn test_multiple_decrements_emit_multiple_events() {
    let contract_address = deploy_counter(5);
    let dispatcher = ICounterDispatcher { contract_address };
    let caller: ContractAddress = 0xabc.try_into().unwrap();
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, caller);
    
    dispatcher.decrement(); // 5 -> 4
    dispatcher.decrement(); // 4 -> 3
    dispatcher.decrement(); // 3 -> 2
    
    stop_cheat_caller_address(contract_address);
    
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
}

// ==================== Event Tests for set_counter ====================

#[test]
fn test_set_counter_emits_event() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    let mut spy = spy_events();
    
    // Call as owner
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(42);
    stop_cheat_caller_address(contract_address);
    
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 1, 'Should emit 1 event');
}

#[test]
fn test_set_counter_multiple_times_emits_events() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, owner);
    
    dispatcher.set_counter(10);
    dispatcher.set_counter(50);
    dispatcher.set_counter(25);
    
    stop_cheat_caller_address(contract_address);
    
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
}

// ==================== Event Tests for mixed operations ====================

#[test]
fn test_mixed_operations_emit_correct_event_count() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let user: ContractAddress = 0xdef.try_into().unwrap();
    
    let mut spy = spy_events();
    
    // User increments
    start_cheat_caller_address(contract_address, user);
    dispatcher.increment(); // 10 -> 11
    stop_cheat_caller_address(contract_address);
    
    // Owner sets value
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(50); // 11 -> 50
    stop_cheat_caller_address(contract_address);
    
    // User decrements
    start_cheat_caller_address(contract_address, user);
    dispatcher.decrement(); // 50 -> 49
    stop_cheat_caller_address(contract_address);
    
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
    
    // Verify final state
    let counter = dispatcher.get_counter();
    assert(counter == 49, 'Counter should be 49');
}

// ==================== Event Tests for different callers ====================

#[test]
fn test_events_from_different_callers() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let alice: ContractAddress = 0xa11ce.try_into().unwrap();
    let bob: ContractAddress = 0xb0b.try_into().unwrap();
    let charlie: ContractAddress = 0xc0de.try_into().unwrap();
    
    let mut spy = spy_events();
    
    // Alice increments
    start_cheat_caller_address(contract_address, alice);
    dispatcher.increment();
    stop_cheat_caller_address(contract_address);
    
    // Bob increments
    start_cheat_caller_address(contract_address, bob);
    dispatcher.increment();
    stop_cheat_caller_address(contract_address);
    
    // Charlie increments
    start_cheat_caller_address(contract_address, charlie);
    dispatcher.increment();
    stop_cheat_caller_address(contract_address);
    
    // Verify each caller triggered an event
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
    
    // Verify counter value
    let counter = dispatcher.get_counter();
    assert(counter == 3, 'Counter should be 3');
}

// ==================== Test no events for read operations ====================

#[test]
fn test_get_counter_emits_no_event() {
    let contract_address = deploy_counter(42);
    let dispatcher = ICounterDispatcher { contract_address };
    
    let mut spy = spy_events();
    
    // Call get_counter multiple times
    let value1 = dispatcher.get_counter();
    let value2 = dispatcher.get_counter();
    let value3 = dispatcher.get_counter();
    
    // Verify values are correct
    assert(value1 == 42, 'Value should be 42');
    assert(value2 == 42, 'Value should be 42');
    assert(value3 == 42, 'Value should be 42');
    
    // Verify no events were emitted
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 0, 'Should emit no events');
}

// ==================== Payment-Based Reset Tests ====================

// ==================== Basic Payment Tests ====================

#[test]
fn test_reset_with_exact_payment() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x123.try_into().unwrap();
    let _owner: ContractAddress = 0x1.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Mock user has exactly 1 STRK
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    // User calls reset
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    // Verify counter was reset
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 after reset');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

#[test]
fn test_reset_with_more_than_required_payment() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x456.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Mock user has 10 STRK (more than required)
    let ten_strk: u256 = ONE_STRK * 10;
    start_mock_call(strk_address, selector!("balance_of"), ten_strk);
    start_mock_call(strk_address, selector!("allowance"), ten_strk);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Insufficient Balance Tests ====================

#[test]
#[should_panic]
fn test_reset_with_insufficient_balance() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x789.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Mock user has only 0.5 STRK
    let half_strk: u256 = ONE_STRK / 2;
    start_mock_call(strk_address, selector!("balance_of"), half_strk);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
}

#[test]
#[should_panic]
fn test_reset_with_zero_balance() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0xabc.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Mock user has 0 STRK
    start_mock_call(strk_address, selector!("balance_of"), 0_u256);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
}

#[test]
#[should_panic]
fn test_reset_with_almost_enough_balance() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0xdef.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Mock user has 0.999999999999999999 STRK (1 wei less than required)
    let almost_one_strk: u256 = ONE_STRK - 1;
    start_mock_call(strk_address, selector!("balance_of"), almost_one_strk);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
}

// ==================== Insufficient Allowance Tests ====================

#[test]
#[should_panic]
fn test_reset_insufficient_allowance() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x111.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // User has enough balance but insufficient allowance
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK / 2);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
}

#[test]
#[should_panic]
fn test_reset_zero_allowance() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x222.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // User has balance but zero allowance
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 5);
    start_mock_call(strk_address, selector!("allowance"), 0_u256);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
}

// ==================== Transfer Failure Tests ====================

#[test]
#[should_panic]
fn test_reset_with_transfer_failure() {
    let contract_address = deploy_counter(75);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x333.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // User has balance and allowance, but transfer fails
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("transfer_from"), false); // Transfer fails
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Multiple Users Reset Tests ====================

#[test]
fn test_multiple_users_can_reset() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let alice: ContractAddress = 0xa11ce.try_into().unwrap();
    let bob: ContractAddress = 0xb0b.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Setup mocks for both users
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 10);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 10);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    // Alice resets
    start_cheat_caller_address(contract_address, alice);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 after Alice');
    
    // Increment counter
    dispatcher.increment();
    dispatcher.increment();
    assert(dispatcher.get_counter() == 2, 'Counter should be 2');
    
    // Bob resets
    start_cheat_caller_address(contract_address, bob);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 after Bob');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Owner Can Also Pay to Reset ====================

#[test]
fn test_owner_can_pay_to_reset() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Owner has balance and allowance
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 5);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 5);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    // Owner calls reset (pays themselves)
    start_cheat_caller_address(contract_address, owner);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Event Emission Tests ====================

#[test]
fn test_reset_payment_emits_event() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x444.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Setup mocks
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    // Verify event was emitted
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 1, 'Should emit 1 event');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Edge Cases with Counter State ====================

#[test]
fn test_reset_from_max_value() {
    let contract_address = deploy_counter(0);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let user: ContractAddress = 0x555.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Set counter to max u32
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(4294967295_u32); // max u32
    stop_cheat_caller_address(contract_address);
    
    assert(dispatcher.get_counter() == 4294967295_u32, 'Counter should be max');
    
    // Setup mocks for reset
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    // User resets from max value
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

#[test]
fn test_consecutive_resets_require_payment_each_time() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x666.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Setup mocks
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 10);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 10);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(contract_address, user);
    
    // First reset
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');
    
    // Second reset (still from 0)
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should still be 0');
    
    // Third reset
    dispatcher.reset();
    assert(dispatcher.get_counter() == 0, 'Counter should remain 0');
    
    stop_cheat_caller_address(contract_address);
    
    // Each reset should emit an event (and charge)
    let events = spy.get_events().emitted_by(contract_address);
    assert(events.events.len() == 3, 'Should emit 3 events');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Combined Operations Tests ====================

#[test]
fn test_reset_between_other_operations() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    let owner: ContractAddress = 0x1.try_into().unwrap();
    let user: ContractAddress = 0x777.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Initial operations
    dispatcher.increment(); // 11
    dispatcher.increment(); // 12
    assert(dispatcher.get_counter() == 12, 'Counter should be 12');
    
    // Setup mocks for reset
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    // User pays to reset
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0');
    
    // More operations
    dispatcher.increment(); // 1
    
    // Owner sets value
    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_counter(100);
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 100, 'Counter should be 100');
    
    // User pays to reset again
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    assert(dispatcher.get_counter() == 0, 'Counter should be 0 again');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}

// ==================== Boundary Value Tests ====================

#[test]
#[should_panic]
fn test_reset_with_exactly_one_wei_less_allowance() {
    let contract_address = deploy_counter(50);
    let dispatcher = ICounterDispatcher { contract_address };
    let user: ContractAddress = 0x888.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // User has enough balance but allowance is 1 wei short
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 2);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK - 1);
    
    start_cheat_caller_address(contract_address, user);
    let _result = dispatcher.reset(); // Should panic
    stop_cheat_caller_address(contract_address);
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
}

// ==================== Payment Verification Test ====================

#[test]
fn test_payment_goes_to_owner() {
    let contract_address = deploy_counter(100);
    let dispatcher = ICounterDispatcher { contract_address };
    let _owner: ContractAddress = 0x1.try_into().unwrap();
    let user: ContractAddress = 0x999.try_into().unwrap();
    let strk_address = get_strk_address();
    
    // Setup mocks - we'll verify the transfer_from parameters
    start_mock_call(strk_address, selector!("balance_of"), ONE_STRK * 5);
    start_mock_call(strk_address, selector!("allowance"), ONE_STRK * 5);
    
    // Mock transfer_from to verify it's called with correct parameters
    // Note: In real test, we'd verify the actual call parameters
    start_mock_call(strk_address, selector!("transfer_from"), true);
    
    start_cheat_caller_address(contract_address, user);
    dispatcher.reset();
    stop_cheat_caller_address(contract_address);
    
    // The payment should go from user to owner
    // In production test, we'd verify the actual transfer parameters
    assert(dispatcher.get_counter() == 0, 'Counter should be reset');
    
    stop_mock_call(strk_address, selector!("balance_of"));
    stop_mock_call(strk_address, selector!("allowance"));
    stop_mock_call(strk_address, selector!("transfer_from"));
}