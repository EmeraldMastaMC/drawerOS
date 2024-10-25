const ports = @import("ports.zig");
const VIDEO_MEMORY: [*]volatile u16 = @ptrFromInt(0xB8000);
const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

pub fn putc(column: usize, row: usize, col: u16, char: u8) void {
    const offset = row * VGA_WIDTH + column;
    if ((offset) < (VGA_WIDTH * VGA_HEIGHT)) {
        VIDEO_MEMORY[offset] = (col << 8) | @as(u16, char);
    }
}

pub fn putcBuf(column: usize, row: usize, col: u16, char: u8, buf: [*]u16) void {
    const offset = row * VGA_WIDTH + column;
    if ((offset) < (VGA_WIDTH * VGA_HEIGHT)) {
        buf[offset] = (col << 8) | @as(u16, char);
    }
}

pub fn setCursorPosition(column: usize, row: usize) void {
    const pos = row * VGA_WIDTH + column;
    ports.outb(0x3D4, 0x0F);
    ports.outb(0x3D5, @truncate(pos & 0xFF));
    ports.outb(0x3D4, 0x0E);
    ports.outb(0x3D5, @truncate((pos >> 8) & 0xFF));
}

pub fn putCharInterrupt(column: usize, row: usize, color: u16, char: u8) void {
    asm volatile (
        \\ int $32
        :
        : [column] "{rdi}" (column),
          [row] "{rsi}" (row),
          [col] "{rdx}" (@as(u64, color)),
          [char] "{r10}" (@as(u64, char)),
    );
}

pub const Color = enum(u8) {
    Black = 0x0,
    Blue = 0x1,
    Green = 0x2,
    Cyan = 0x3,
    Red = 0x4,
    Magenta = 0x5,
    Brown = 0x6,
    LightGray = 0x7,
    DarkGray = 0x8,
    LightBlue = 0x9,
    LightGreen = 0xA,
    LightCyan = 0xB,
    LightRed = 0xC,
    LightMagenta = 0xD,
    Yellow = 0xE,
    White = 0xF,
};
pub const Writer = struct {
    fg_color: Color,
    bg_color: Color,
    column: usize = 0,
    row: usize = 0,
    cursor: bool = false,
    back_buffer: [*]u16,

    pub fn new(fg_color: Color, bg_color: Color, buf: [*]u16) Writer {
        var writer = Writer{ .fg_color = fg_color, .bg_color = bg_color, .back_buffer = buf };
        writer.disableCursor();
        writer.zero_buffer();
        return writer;
    }

    pub fn newFromStart(fg_color: Color, bg_color: Color, column: usize, row: usize, buf: [*]u16) Writer {
        var writer = Writer{ .fg_color = fg_color, .bg_color = bg_color, .column = column, .row = row, .back_buffer = buf };
        writer.disableCursor();
        writer.zero_buffer();
        return writer;
    }

    pub fn fromRawWriter(writer: RawWriter, buf: [*]u16) Writer {
        var ret_writer = Writer{ .fg_color = writer.fg_color, .bg_color = writer.bg_color, .row = writer.row, .column = writer.column, .cursor = writer.cursor, .back_buffer = buf };
        ret_writer.zero_buffer();
        return ret_writer;
    }

    pub fn putLn(self: *Writer) void {
        self.putChar('\n');
    }

    pub fn putChar(self: *Writer, char: u8) void {
        if (char == '\n') {
            self.column = 0;
            self.row += 1;
            if (self.cursor) {
                self.updateCursor();
            }
            if (self.row == VGA_HEIGHT) {
                self.scroll();
            }
        } else {
            putcBuf(self.column, self.row, (@intFromEnum(self.bg_color) << 4) | @intFromEnum(self.fg_color), char, self.back_buffer);
            self.column += 1;
            if (self.column == VGA_WIDTH) {
                self.column = 0;
                self.row += 1;
            }
            if (self.row == VGA_HEIGHT) {
                self.scroll();
            }

            if (self.cursor) {
                self.updateCursor();
            }
        }
    }
    pub fn putHex(self: *Writer, num: u64) void {
        var hex = num;
        var i: usize = 16;
        self.putString("0x");
        while (i > 0) {
            const char: u8 = switch (@as(u4, @truncate((hex & 0xF000000000000000) >> 60))) {
                0x0 => '0',
                0x1 => '1',
                0x2 => '2',
                0x3 => '3',
                0x4 => '4',
                0x5 => '5',
                0x6 => '6',
                0x7 => '7',
                0x8 => '8',
                0x9 => '9',
                0xA => 'A',
                0xB => 'B',
                0xC => 'C',
                0xD => 'D',
                0xE => 'E',
                0xF => 'F',
            };
            self.putChar(char);
            hex <<= 4;
            i -= 1;
        }
    }
    pub fn putString(self: *Writer, str: []const u8) void {
        for (str) |char| {
            self.putChar(char);
        }
    }

    pub fn putCString(self: *Writer, str: [*]u8) void {
        var i: usize = 0;
        while (true) {
            if (str[i] == 0) {
                break;
            } else {
                self.putChar(str[i]);
            }
            i += 1;
        }
    }

    pub fn setColors(self: *Writer, fg_color: Color, bg_color: Color) void {
        self.setFgColor(fg_color);
        self.setBgColor(bg_color);
    }

    pub fn setFgColor(self: *Writer, fg_color: Color) void {
        self.fg_color = fg_color;
    }

    pub fn setBgColor(self: *Writer, bg_color: Color) void {
        self.bg_color = bg_color;
    }

    pub fn clear(self: *Writer) void {
        for (0..VGA_HEIGHT) |_| {
            for (0..VGA_WIDTH) |_| {
                self.putChar(' ');
            }
        }
        self.column = 0;
        self.row = 0;
    }

    pub fn flush(self: *Writer) void {
        for (0..VGA_HEIGHT) |row| {
            for (0..VGA_WIDTH) |col| {
                putCharInterrupt(col, row, (self.back_buffer[row * VGA_WIDTH + col] & 0xFF00) >> 8, @truncate(self.back_buffer[row * VGA_WIDTH + col] & 0x00FF));
            }
        }
    }

    pub fn scroll(self: *Writer) void {
        for (1..VGA_HEIGHT) |row| {
            for (0..VGA_WIDTH) |col| {
                self.back_buffer[(row - 1) * VGA_WIDTH + col] = self.back_buffer[row * VGA_WIDTH + col];
            }
        }
        for (0..VGA_WIDTH) |col| {
            self.back_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + col] = 0;
        }
        self.row -= 1;
    }

    // Cursor functions: wiki.osdev.org/Text_Mode_Cursor
    pub fn disableCursor(_: *Writer) void {
        ports.outb(0x3D4, 0x0A);
        ports.outb(0x3D5, 0x20);
    }

    pub fn enableCursor(self: *Writer) void {
        self.cursor = true;
        ports.outb(0x3D4, 0x0A);
        ports.outb(0x3D5, (ports.inb(0x3D5) & 0xC0) | 0);
        ports.outb(0x3D4, 0x0B);
        ports.outb(0x3D5, (ports.inb(0x3D5) & 0xE0) | 15);
        self.updateCursor();
    }

    fn updateCursor(self: *Writer) void {
        setCursorPosition(self.column, self.row);
    }

    fn zero_buffer(self: *Writer) void {
        // Trickery so that memset isn't called
        var i: usize = 0;
        while (i < (VGA_WIDTH * VGA_HEIGHT)) {
            const addr: [*]u16 = @ptrFromInt(@intFromPtr(self.back_buffer) + i * 2);
            addr[0] = 0;
            i += 1;
        }
    }
};

// Writer, But It doesn't rely on interrupts
pub const RawWriter = struct {
    fg_color: Color,
    bg_color: Color,
    column: usize = 0,
    row: usize = 0,
    cursor: bool = false,

    pub fn new(fg_color: Color, bg_color: Color) RawWriter {
        var writer = RawWriter{ .fg_color = fg_color, .bg_color = bg_color };
        writer.disableCursor();
        return writer;
    }

    pub fn newFromStart(fg_color: Color, bg_color: Color, column: usize, row: usize) RawWriter {
        var writer = RawWriter{ .fg_color = fg_color, .bg_color = bg_color, .column = column, .row = row };
        writer.disableCursor();
        return writer;
    }

    pub fn fromWriter(writer: Writer) RawWriter {
        return RawWriter{ .fg_color = writer.fg_color, .bg_color = writer.bg_color, .row = writer.row, .column = writer.column, .cursor = writer.cursor };
    }

    pub fn putLn(self: *RawWriter) void {
        self.putChar('\n');
    }

    pub fn putChar(self: *RawWriter, char: u8) void {
        if (char == '\n') {
            self.column = 0;
            self.row += 1;
            if (self.cursor) {
                self.updateCursor();
            }
            if (self.row == VGA_HEIGHT) {
                self.row = 0;
                self.column = 0;
            }
        } else {
            putc(self.column, self.row, (@intFromEnum(self.bg_color) << 4) | @intFromEnum(self.fg_color), char);
            self.column += 1;
            if (self.column == VGA_WIDTH) {
                self.column = 0;
                self.row += 1;
            }
            if (self.row == VGA_HEIGHT) {
                self.row = 0;
                self.column = 0;
            }

            if (self.cursor) {
                self.updateCursor();
            }
        }
    }
    pub fn putHex(self: *RawWriter, num: u64) void {
        var hex = num;
        var i: usize = 16;
        self.putString("0x");
        while (i > 0) {
            const char: u8 = switch (@as(u4, @truncate((hex & 0xF000000000000000) >> 60))) {
                0x0 => '0',
                0x1 => '1',
                0x2 => '2',
                0x3 => '3',
                0x4 => '4',
                0x5 => '5',
                0x6 => '6',
                0x7 => '7',
                0x8 => '8',
                0x9 => '9',
                0xA => 'A',
                0xB => 'B',
                0xC => 'C',
                0xD => 'D',
                0xE => 'E',
                0xF => 'F',
            };
            self.putChar(char);
            hex <<= 4;
            i -= 1;
        }
    }
    pub fn putString(self: *RawWriter, str: []const u8) void {
        for (str) |char| {
            self.putChar(char);
        }
    }

    pub fn putCString(self: *RawWriter, str: [*]u8) void {
        var i: usize = 0;
        while (true) {
            if (str[i] == 0) {
                break;
            } else {
                self.putChar(str[i]);
            }
            i += 1;
        }
    }
    pub fn setColors(self: *RawWriter, fg_color: Color, bg_color: Color) void {
        self.setFgColor(fg_color);
        self.setBgColor(bg_color);
    }

    pub fn setFgColor(self: *RawWriter, fg_color: Color) void {
        self.fg_color = fg_color;
    }

    pub fn setBgColor(self: *RawWriter, bg_color: Color) void {
        self.bg_color = bg_color;
    }

    pub fn clear(self: *RawWriter) void {
        for (0..VGA_HEIGHT) |_| {
            for (0..VGA_WIDTH) |_| {
                self.putChar(' ');
            }
        }
        self.column = 0;
        self.row = 0;
    }

    // Cursor functions: wiki.osdev.org/Text_Mode_Cursor
    pub fn disableCursor(_: *RawWriter) void {
        ports.outb(0x3D4, 0x0A);
        ports.outb(0x3D5, 0x20);
    }

    pub fn enableCursor(self: *RawWriter) void {
        self.cursor = true;
        ports.outb(0x3D4, 0x0A);
        ports.outb(0x3D5, (ports.inb(0x3D5) & 0xC0) | 0);
        ports.outb(0x3D4, 0x0B);
        ports.outb(0x3D5, (ports.inb(0x3D5) & 0xE0) | 15);
        self.updateCursor();
    }

    fn updateCursor(self: *RawWriter) void {
        setCursorPosition(self.column, self.row);
    }
};
