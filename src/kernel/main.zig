const idt = @import("idt.zig");
const paging = @import("paging.zig");
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);

// For information on the stucture of PML4Entry, PDPEntry, PDEntry, and PTEntry, please refer to section 5.3.3 of the manual
const PML4_ENTRIES: usize = 1;
const PDP_ENTRIES: usize = 1;
const PD_ENTRIES: usize = 2;
const PT_ENTRIES: usize = 512;

// Page Map Level 4 (PML4) Table
var PML4: [PML4_ENTRIES]paging.PML4Entry align(4096) = undefined;
// Page Directory Pointer (PDP) Table
var PDP: [PDP_ENTRIES]paging.PDPEntry align(4096) = undefined;
// Page Directory (PD) Table
var PD: [PD_ENTRIES]paging.PDEntry align(4096) = undefined;
// Page Table (PT) Table
var PT: [PT_ENTRIES]paging.PTEntry align(4096) = undefined;

export fn main() noreturn {
    idt.entry(0x0, @as(usize, @intFromPtr(&lots_of_x)));
    idt.load();
    // paging.load_pml4(&PML4[0]);
    asm volatile ("int $0x0");

    VIDEO_MEMORY[6] = 0x0500 | @as(u16, 'H');
    while (true) {}
}

fn lots_of_x() callconv(.Interrupt) void {
    for (0..(VGA_WIDTH * VGA_HEIGHT)) |i| {
        VIDEO_MEMORY[i] = 0x0F00 | @as(u16, 'X');
    }
}
