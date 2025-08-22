use debug::PrintTrait;

fn main() {
    let original_price = 51_u32;
    sale_price(original_price).print();
}

fn sale_price(price: u32) -> u32 {
    if is_even(price) {
        price - 10_u32
    } else {
        price - 3_u32
    }
}

fn is_even(num: u32) -> bool {
    num % 2_u32 == 0_u32
}
