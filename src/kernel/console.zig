const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

pub fn printChar(x: usize, y: usize, col: u16, char: u8) void {
    const offset = y * VGA_WIDTH + x;
    if ((offset) < (VGA_WIDTH * VGA_HEIGHT)) {
        VIDEO_MEMORY[offset] = (col << 8) | @as(u16, char);
    }
}
