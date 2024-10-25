const page_frame_allocator = @import("page_frame_allocator.zig");
pub fn alloc(size: usize) usize {
    const frame = page_frame_allocator.alloc(size);
    return (0x1000 * size) + frame - 1;
}

pub inline fn init(addr: usize) void {
    asm volatile (
        \\ mov %[addr], %rsp
        \\ mov %[addr], %rbp
        :
        : [addr] "{rax}" (addr),
    );
}
