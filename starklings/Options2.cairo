use option::OptionTrait;
use debug::PrintTrait;

#[test]
fn test_options() {
    let target = 'starklings';
    let optional_some: Option<felt252> = Option::Some(target);
    let optional_none: Option<felt252> = Option::None(());
    simple_option(optional_some);
    simple_option(optional_none);
}

fn simple_option(optional_target: Option<felt252>) {
    match optional_target {
        Option::Some(_target) => { assert(optional_target.unwrap() == 'starklings', 'err1'); },
        Option::None(_) => { ('option is empty !').print(); },
    }
}
