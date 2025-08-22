use array::ArrayTrait;
use array::ArrayTCloneImpl;
use array::SpanTrait;
use clone::Clone;
use debug::PrintTrait;

fn main() {
    let mut arr0 = ArrayTrait::new();

    arr0.append(88);

    arr0.span().snapshot.clone().print();
}

fn fill_arr(ref arr: Array<felt252>) {
    arr.append(22);
    arr.append(44);
    arr.append(66);
}
