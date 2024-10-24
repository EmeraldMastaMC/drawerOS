pub const Allocator = struct {
    bitmap: u32768 = 0,

    pub fn new() Allocator {
        return Allocator{};
    }
};
