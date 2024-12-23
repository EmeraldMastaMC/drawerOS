const page_allocator = @import("page_frame_allocator.zig");
pub const Heap = struct {
    heap_addr: usize,
    bitmap: [*]allowzero volatile u1,
    bitmap_len: usize,
    amnt_pages: usize,

    pub fn new(amnt_pages: usize) Heap {
        var heap = Heap{
            .heap_addr = page_allocator.alloc(amnt_pages),
            .bitmap = @ptrFromInt(page_allocator.alloc((amnt_pages / 8) + 1)),
            .bitmap_len = (((amnt_pages / 8) + 1) * 4096),
            .amnt_pages = amnt_pages,
        };
        heap.init();
        return heap;
    }
    fn init(self: *Heap) void {
        for (0..self.bitmap_len) |i| {
            self.bitmap[i] = 0;
        }
    }

    pub fn alloc(self: *Heap, bytes: usize, alignment: usize) *allowzero void {
        if ((alignment == 0) or (alignment == 1)) {
            return self.alloc_no_align(bytes);
        } else {
            const heap_bytes = self.amnt_pages * 4096;
            if (bytes > heap_bytes) {
                // Null pointer
                return @ptrFromInt(0);
            } else {
                var window_index: usize = 0;
                while (true) {
                    // A window of bits, starting from window index with bytes number of indices
                    const window = self.bitmap[window_index..(bytes + window_index)];
                    var detected_byte_in_use = false;

                    // If there is a bit set, that means a byte in the window is in use
                    var i: usize = 0;
                    while (i != bytes) {
                        if (window[i] == 1) {
                            detected_byte_in_use = true;
                            break;
                        }
                        i += 1;
                    }

                    // We detected a byte in use, forward to the index after the last set bit in the window
                    if (detected_byte_in_use) {
                        var j = bytes - 1;
                        while (true) { // This is guaranteed to end, because we already know a bit is set
                            if (window[j] == 1) {
                                window_index += alignment; // Forward to the index after the last set bit
                                if (window_index > (self.bitmap_len - bytes)) { // Makes sure we have enough pages left to play with
                                    // null pointer
                                    return @ptrFromInt(0);
                                }
                                break;
                            }
                            j -= 1;
                        }
                    } else { // We didn't detect a byte in use, return the start of the window's address, and set all bits in the window
                        var k: usize = 0;
                        while (k != bytes) {
                            self.bitmap[window_index + k] = 1;
                            k += 1;
                        }
                        return @ptrFromInt(self.heap_addr + window_index);
                    }
                }
            }
        }
    }
    pub fn alloc_no_align(self: *Heap, bytes: usize) *allowzero void {
        const heap_bytes = self.amnt_pages * 4096;
        if (bytes > heap_bytes) {
            // Null pointer
            return @ptrFromInt(0);
        } else {
            var window_index: usize = 0;
            while (true) {
                // A window of bits, starting from window index with bytes number of indices
                const window = self.bitmap[window_index..(bytes + window_index)];
                var detected_byte_in_use = false;

                // If there is a bit set, that means a byte in the window is in use
                var i: usize = 0;
                while (i != bytes) {
                    if (window[i] == 1) {
                        detected_byte_in_use = true;
                        break;
                    }
                    i += 1;
                }

                // We detected a byte in use, forward to the index after the last set bit in the window
                if (detected_byte_in_use) {
                    var j = bytes - 1;
                    while (true) { // This is guaranteed to end, because we already know a bit is set
                        if (window[j] == 1) {
                            window_index += j + 1; // Forward to the index after the last set bit
                            if (window_index > (self.bitmap_len - bytes)) { // Makes sure we have enough pages left to play with
                                // null pointer
                                return @ptrFromInt(0);
                            }
                            break;
                        }
                        j -= 1;
                    }
                } else { // We didn't detect a byte in use, return the start of the window's address, and set all bits in the window
                    var k: usize = 0;
                    while (k != bytes) {
                        self.bitmap[window_index + k] = 1;
                        k += 1;
                    }
                    return @ptrFromInt(self.heap_addr + window_index);
                }
            }
        }
    }
    pub fn free(self: *Heap, addr: *allowzero void, bytes: usize) void {
        const index = self.addrToBitmapPos(@intFromPtr(addr));
        for (index..(index + bytes)) |i| {
            self.bitmap[i] = 0;
        }
    }

    pub fn deinit(self: *Heap) void {
        page_allocator.free(self.heap_addr, self.amnt_pages);
        page_allocator.free(@intFromPtr(self.bitmap), self.bitmap_len / 4096);
    }

    fn addrToBitmapPos(self: *Heap, addr: usize) usize {
        return addr - self.heap_addr;
    }
};
