const cpu = @import("cpu.zig");
const paging = @import("paging.zig");
const allocator = @import("page_frame_allocator.zig");
const console = @import("console.zig");
const colors = console.Color;
const magic = (' ' << 56) | ('R' << 48) | ('T' << 40) | ('P' << 32) | (' ' << 24) | ('D' << 16) | ('S' << 8) | ('R' << 0);
const magic_mcfg: u32 = ('G' << 24) | ('F' << 16) | ('C' << 8) | ('M' << 0);
const acpi_size = 0x20000;
const acpi: [*]volatile u64 = @ptrFromInt(0xE0000);
var rsdp: u64 = 0x00;
var rsdt: u64 = 0x00;
const Rsdp = packed struct {
    signature: u64,
    checksum: u8,
    oemid: u48,
    revision: u8,
    rsdt_address: u32, // Deprecated
};
pub fn findMagic() void {
    var found_magic = false;
    const back_buffer: [*]volatile u16 = @alignCast(@ptrCast(allocator.alloc(1)));
    defer allocator.free(@ptrCast(back_buffer), 1);
    var writer = console.Writer.new(colors.White, colors.Black, back_buffer);
    for (0..acpi_size) |i| {
        const addr: *volatile u64 = @ptrFromInt(@intFromPtr(acpi) + i);
        if (addr.* == magic) {
            found_magic = true;
            rsdp = @intFromPtr(addr);
            break;
        }
    }
    if (found_magic) {
        found_magic = false;
        writer.putString("FOUND MAGIC\x00");
        writer.putLn();
        writer.putHexLong(@as(*volatile Rsdp, @ptrFromInt(rsdp)).rsdt_address);
        writer.putLn();
        writer.putString("Virtual Address: \x00");
        const pages = allocator.alloc(1);
        writer.putHexQuad(@intFromPtr(pages));
        writer.putLn();

        writer.flush();
        for (0..1) |i| {
            paging.mapPage(@as(u64, @as(*volatile Rsdp, @ptrFromInt(rsdp)).*.rsdt_address) + i * 0x1000, @intFromPtr(pages) + i * 0x1000);
        }
        rsdt = @intFromPtr(pages) + (rsdt & 0xFFF);
        for (0..0x1000) |i| {
            const addr: *volatile u32 = @ptrFromInt(rsdt + i);
            if (addr.* == magic_mcfg) {
                found_magic = true;
                break;
            }
        }
    }

    if (found_magic) {
        writer.putLn();
        writer.putString("FOUND MCFG!!!\x00");
    } else {
        writer.putLn();
        writer.putString("NOPE!\x00");
    }
    writer.flush();
}
