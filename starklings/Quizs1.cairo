fn calculate_price_of_apples(apples: usize) -> usize {
    if apples > 40_usize {
        return apples * 2_usize;
    } else {
        return apples * 3_usize;
    }
}


// Do not change the tests!
#[test]
fn verify_test() {
    let price1 = calculate_price_of_apples(35_usize);
    let price2 = calculate_price_of_apples(40_usize);
    let price3 = calculate_price_of_apples(41_usize);
    let price4 = calculate_price_of_apples(65_usize);

    assert(105_usize == price1, 'Incorrect price');
    assert(120_usize == price2, 'Incorrect price');
    assert(82_usize == price3, 'Incorrect price');
    assert(130_usize == price4, 'Incorrect price');
}
