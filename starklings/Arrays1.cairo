use array::ArrayTrait;
use option::OptionTrait;

fn create_array() -> Array<felt252> {
    let mut a: Array<felt252> = ArrayTrait::new();
    a.append(0);
    a.append(1);
    a.append(2);
    a
}


// Don't change anything in the test
#[test]
fn test_array_len() {
    let mut a = create_array();
    assert(a.len() == 3_usize, 'Array length is not 3');
    assert(a.pop_front().unwrap() == 0, 'First element is not 0');
}
