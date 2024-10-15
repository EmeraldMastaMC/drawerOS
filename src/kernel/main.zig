const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
export fn main() noreturn {
    const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);
    for (0..(VGA_WIDTH * VGA_HEIGHT)) |i| {
        VIDEO_MEMORY[i] = 0x0F00 | @as(u16, 'X');
    }
    while (true) {}
}
