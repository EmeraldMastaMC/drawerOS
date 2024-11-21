const page_frame_allocator = @import("page_frame_allocator.zig");
const paging = @import("paging.zig");
pub fn alloc(size: usize) usize {
    const frame = @intFromPtr(page_frame_allocator.alloc(size));
    return (paging.PAGE_SIZE * size) + frame - 1;
}

pub inline fn init(addr: usize) void {
    asm volatile (
        \\ mov %[addr], %rsp
        \\ mov %[addr], %rbp
        :
        : [addr] "{rax}" (addr),
    );
}
