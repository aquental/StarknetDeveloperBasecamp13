use debug::PrintTrait;

fn main() {
    call_me(5_u64);
}

fn call_me(num: u64) {
    num.print();
}
