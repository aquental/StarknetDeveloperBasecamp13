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
