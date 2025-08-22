use debug::PrintTrait;

fn main() {
    let cat = ('Furry McFurson', 3);
    let (name, age) = cat;
    name.print();
    age.print();
}
