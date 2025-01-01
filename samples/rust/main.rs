use std::io;

fn test() {
    println!("Hello, world!")
}

fn main() {
    println!("Enter a number:");

    let mut input = String::new();

    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    let number: u32 = match input.trim().parse() {
        Ok(num) => num,
        Err(_) => {
            println!("Please enter a valid number!");
            return;
        }
    };

    testers()

    for _ in 0..number {
        println!("hello");
    }
}
