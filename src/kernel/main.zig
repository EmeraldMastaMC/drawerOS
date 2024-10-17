const idt = @import("idt.zig");
const paging = @import("paging.zig");
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);

// Page Map Level 4 (PML4) Table
var PML4 align(4096) = [_]paging.PML4Entry{paging.PML4Entry.new(0, true, false, false, false, 0, 0, false)} ** paging.TOTAL_PML4_ENTRIES;
// Page Directory Pointer (PDP) Table
var PDP align(4096) = [_]paging.PDPEntry{paging.PDPEntry.new(0, true, false, false, false, 0, 0, false)} ** paging.TOTAL_PDP_ENTRIES;
// Page Directory (PD) Table
var PD align(4096) = [_]paging.PDEntry{paging.PDEntry.new(0, true, false, false, false, 0, 0, false)} ** paging.TOTAL_PD_ENTRIES;
// Page Table (PT) Table
var PT align(4096) = [_]paging.PTEntry{paging.PTEntry.new(
    0,
    false,
    false,
    false,
    false,
    false,
    0,
    0,
    false,
)} ** paging.TOTAL_PT_ENTRIES;

export fn main() noreturn {
    idt.entry(0x0, @as(usize, @intFromPtr(&lots_of_x)));
    idt.load();

    paging.identityMap(@ptrCast(&PML4[0]), @ptrCast(&PDP[0]), @ptrCast(&PD[0]), @ptrCast(&PT[0]));
    // asm volatile ("int $0x0");
    //
    // VIDEO_MEMORY[6] = 0x0500 | @as(u16, 'H');
    while (true) {}
}

fn lots_of_x() callconv(.Interrupt) void {
    for (0..(VGA_WIDTH * VGA_HEIGHT)) |i| {
        VIDEO_MEMORY[i] = 0x0F00 | @as(u16, 'X');
    }
}
