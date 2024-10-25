const main = @import("main.zig");
const TOTAL_PT_ENTRIES = main.PML4_ENTRIES * main.PDP_ENTRIES * main.PD_ENTRIES * main.PT_ENTRIES;
const KERNEL_START: usize = 0x7E00;

var page_bitmap: [TOTAL_PT_ENTRIES]u1 = [_]u1{0} ** TOTAL_PT_ENTRIES;
pub fn init() void {
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
pub fn alloc_page() usize {
    for (0..TOTAL_PT_ENTRIES) |i| {
        if (page_bitmap[i] == 0) {
            page_bitmap[i] = 1;
            return bitmapPosToAddr(i);
        }
    }
    // Null pointer
    return 0;
}

pub fn alloc(amnt_pages: usize) usize {
    // If we are trying to allocate more pages than we have to allocate
    if (amnt_pages > page_bitmap.len) {
        // Null pointer
        return 0;
    } else {
        var window_index: usize = 0;
        while (true) {
            // A window of bits, starting from window index with amnt_pages number of indices
            const window = page_bitmap[window_index..(amnt_pages + window_index)];
            var detected_page_in_use = false;

            // If there is a bit set, that means a page in the window is in use
            var i: usize = 0;
            while (i != amnt_pages) {
                if (window[i] == 1) {
                    detected_page_in_use = true;
                    break;
                }
                i += 1;
            }

            // We detected a page in use, forward to the index after the last set bit in the window
            if (detected_page_in_use) {
                var j = amnt_pages - 1;
                while (true) { // This is guaranteed to end, because we already know a bit is set
                    if (window[j] == 1) {
                        window_index += j + 1; // Forward to the index after the last set bit
                        if (window_index > (page_bitmap.len - amnt_pages)) { // Makes sure we have enough pages left to play with
                            // null pointer
                            return 0;
                        }
                        break;
                    }
                    j -= 1;
                }
            } else { // We didn't detect a page in use, return the start of the window's address, and set all bits in the window
                var k: usize = 0;
                while (k != amnt_pages) {
                    page_bitmap[window_index + k] = 1;
                    k += 1;
                }
                return bitmapPosToAddr(window_index);
            }
        }
    }
}

pub fn free_page(addr: usize) void {
    const index = addrToBitmapPos(addr);
    page_bitmap[index] = 0;
}

pub fn free(addr: usize, amnt_pages: usize) void {
    const index = addrToBitmapPos(addr);
    for (index..(index + amnt_pages)) |i| {
        page_bitmap[i] = 0;
    }
}

inline fn addrToBitmapPos(addr: usize) usize {
    return addr >> 12;
}

inline fn bitmapPosToAddr(pos: usize) usize {
    return pos << 12;
}
