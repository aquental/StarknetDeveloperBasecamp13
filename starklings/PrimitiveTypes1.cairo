use debug::PrintTrait;

fn main() {
    // Booleans (`bool`)

    let is_morning: bool = true;
    if is_morning {
        ('Good morning!').print();
    }

    let is_evening: bool = false;
    if is_evening {
        ('Good evening!').print();
    }
}
