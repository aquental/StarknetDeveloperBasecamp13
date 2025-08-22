fn maybe_icecream(time_of_day: usize) -> Option<usize> {
    if time_of_day > 23_usize {
        Option::Some(0_usize)
    } else if time_of_day < 22_usize {
        Option::Some(5_usize)
    } else {
        Option::None(())
    }
}

#[test]
fn check_icecream() {
    assert(maybe_icecream(9).unwrap() == 5, 'err_1');
    assert(maybe_icecream(10).unwrap() == 5, 'err_2');
    assert(maybe_icecream(23).unwrap() == 0, 'err_3');
    assert(maybe_icecream(22).unwrap() == 0, 'err_4');
    assert(maybe_icecream(25).is_none(), 'err_5');
}

#[test]
fn raw_value() {
    // TODO: Fix this test. How do you get at the value contained in the Option?
    let icecreams = maybe_icecream(12_usize);
    assert(icecreams.unwrap() == 5, 'err_6');
}
