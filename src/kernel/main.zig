const IDT = @import("idt.zig");
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);
export fn main() noreturn {
    IDT.entry(0x0, @as(usize, @intFromPtr(&lots_of_x)));
    IDT.load();
    asm volatile ("int $0x0");

    VIDEO_MEMORY[6] = 0x0500 | @as(u16, 'H');
    while (true) {}
}

fn lots_of_x() callconv(.Interrupt) void {
    for (0..(VGA_WIDTH * VGA_HEIGHT)) |i| {
        VIDEO_MEMORY[i] = 0x0F00 | @as(u16, 'X');
    }
}
