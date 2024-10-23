const main = @import("main.zig");
const TOTAL_PT_ENTRIES = main.PML4_ENTRIES * main.PDP_ENTRIES * main.PD_ENTRIES * main.PT_ENTRIES;
const KERNEL_START: usize = 0x7E00;

var page_bitmap: [TOTAL_PT_ENTRIES]u1 = [_]u1{0} ** TOTAL_PT_ENTRIES;
pub const Allocator = struct {
    // Makes sure that the allocator knows of the kernel's existence and where pages tables are loaded

    pub fn new() Allocator {
        return Allocator{};
    }
    pub fn init(_: *Allocator) void {
        // Kernel Space (10 pages)
        for (0..10) |i| {
            page_bitmap[addrToBitmapPos(KERNEL_START) + i] |= 1;
        }

        // PML4 Table
        for (0..1) |i| {
            const index = addrToBitmapPos(@intFromPtr(main.PML4)) + i;
            page_bitmap[index] |= 1;
        }

        // PDP Table
        for (0..(main.PML4_ENTRIES)) |i| {
            const index = addrToBitmapPos(@intFromPtr(main.PDP)) + i;
            page_bitmap[index] |= 1;
        }

        // PD Table
        for (0..(main.PML4_ENTRIES * main.PDP_ENTRIES)) |i| {
            const index = addrToBitmapPos(@intFromPtr(main.PD)) + i;
            page_bitmap[index] |= 1;
        }

        // PT Table
        for (0..(main.PML4_ENTRIES * main.PDP_ENTRIES * main.PD_ENTRIES)) |i| {
            const index = addrToBitmapPos(@intFromPtr(main.PT)) + i;
            page_bitmap[index] |= 1;
        }

        // Video memory
        page_bitmap[0xb8] |= 1;

        // Page 0. This is not able to be allocated so that we can use a null pointer for an error in the alloc function
        page_bitmap[0] |= 1;
    }
    pub fn alloc(_: *Allocator) usize {
        for (0..TOTAL_PT_ENTRIES) |i| {
            if (page_bitmap[i] == 0) {
                page_bitmap[i] = 1;
                return bitmapPosToAddr(i);
            }
        }
        // Null pointer
        return 0;
    }

    pub fn free(_: *Allocator, addr: usize) void {
        const index = addrToBitmapPos(addr);
        page_bitmap[index] = 0;
    }

    inline fn addrToBitmapPos(addr: usize) usize {
        return addr >> 12;
    }

    inline fn bitmapPosToAddr(pos: usize) usize {
        return pos << 12;
    }
};
