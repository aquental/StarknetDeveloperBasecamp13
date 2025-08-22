use debug::PrintTrait;

fn main() {
    call_me(3);
}

fn call_me(num: felt252) {
    num.print();
}
