pub fn pow(base: u64, exp: u64) u64 {
    var result: u64 = 1;
    for (0..exp) |_| {
        result *= base;
    }
    return result;
}
