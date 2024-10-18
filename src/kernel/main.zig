const idt = @import("idt.zig");
const paging = @import("paging.zig");
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

// const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);
const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xC0000); // Proof of concept that paging works. real video memory is at 0xb8000

// MODIFY THESE VALUES IF YOU MODIFY paging.TOTAL_ENTRIES
var PML4: [*]volatile paging.PML4Entry = @ptrFromInt(0x1000);
var PDP: [*]volatile paging.PDPEntry = @ptrFromInt(0x2000);
var PD: [*]volatile paging.PDEntry = @ptrFromInt(0x3000);
var PT: [*]volatile paging.PTEntry = @ptrFromInt(0x4000);

export fn main() noreturn {
    paging.identityMap(PML4, PDP, PD, PT);
    paging.mapPage(@ptrFromInt(0xB8000), @ptrFromInt(0xC0000), PML4, PDP, PD, PT, false, false, false, false, false, false);

    idt.entry(0x0, @as(usize, @intFromPtr(&lots_of_x)));
    idt.load();
    asm volatile ("int $0x0");

    VIDEO_MEMORY[6] = 0x0500 | @as(u16, 'H');
    while (true) {}
}

fn lots_of_x() callconv(.Interrupt) void {
    for (0..(VGA_WIDTH * VGA_HEIGHT)) |i| {
        VIDEO_MEMORY[i] = 0x0F00 | @as(u16, 'X');
    }
}
