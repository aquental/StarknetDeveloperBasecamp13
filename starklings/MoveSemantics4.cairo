use array::ArrayTrait;
use array::ArrayTCloneImpl;
use array::SpanTrait;
use clone::Clone;
use debug::PrintTrait;

fn main() {

    let mut arr1 = fill_arr();

    arr1.span().snapshot.clone().print();

    arr1.append(88);

    arr1.span().snapshot.clone().print();
}

// `fill_arr()` should no longer takes `arr: Array<felt252>` as argument
fn fill_arr() -> Array<felt252> {
    
    // Use the reference to arr0 to create a new Array
    let mut arr = ArrayTrait::<felt252>::new();
    

    arr.append(22);
    arr.append(44);
    arr.append(66);

    arr
}
