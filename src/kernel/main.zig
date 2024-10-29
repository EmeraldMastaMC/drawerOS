const idt = @import("idt.zig");
const irq = @import("irq.zig");
const cpu = @import("cpu.zig");
const paging = @import("paging.zig");
const console = @import("console.zig");
const colors = console.Color;
const allocator = @import("page_frame_allocator.zig");
const heap_allocator = @import("heap_allocator.zig");
const stack = @import("stack.zig");
const pci = @import("pci.zig");

pub const PML4: [*]volatile paging.PML4Entry = @ptrFromInt(0x1000);
pub const PDP: [*]volatile paging.PDPEntry = @ptrFromInt(0x2000);
pub const PD: [*]volatile paging.PDEntry = @ptrFromInt(0x3000);
pub const PT: [*]volatile paging.PTEntry = @ptrFromInt(0xc0000);

pub const PML4_ENTRIES: u64 = 1;
pub const PDP_ENTRIES: u64 = 1;
pub const PD_ENTRIES: u64 = 300;
pub const PT_ENTRIES: u64 = 512;

export fn main() noreturn {
    // Use a writer that doesn't depend on interrupts to function.
    var raw_writer = console.RawWriter.new(colors.White, colors.Black);
    raw_writer.clear();

    // Maps 600 MB
    raw_writer.putString("Identity Mapping 600MiB...\n");
    paging.identityMap(PML4, PML4_ENTRIES, PDP, PDP_ENTRIES, PD, PD_ENTRIES, PT, PT_ENTRIES);
    raw_writer.putString("Done.\n");

    raw_writer.putString("Initializing Page Frame Allocator...\n");
    allocator.init();
    raw_writer.putString("Done.\n");

    raw_writer.putString("Allocating Stack 40KiB...\n");
    stack.init(allocator.alloc(10));
    raw_writer.putString("Done.\n");

    // Load IRQ 32 with a function, and then load the IDT.
    raw_writer.putString("Loading Interrupt Descriptor Table...\n");
    idt.entry(32, @as(usize, @intFromPtr(&irq.irq32)));
    idt.load();
    raw_writer.putString("Done.\n");

    // Use a writer that depends on interrupts to function.
    const back_buffer: [*]volatile u16 = @ptrFromInt(allocator.alloc(10));
    defer allocator.free(@intFromPtr(back_buffer), 10);
    var writer = console.Writer.new(colors.White, colors.Black, back_buffer);
    writer.enableCursor();
    writer.putLn();
    writer.setColors(colors.LightGreen, colors.Black);
    writer.putString("Welcome to DrawerOS!\n");
    writer.setColors(colors.White, colors.Black);
    writer.putLn();

    {
        writer.putString("Creating a 40KiB heap...\n");
        var heap = heap_allocator.Heap.new(10);
        writer.putString("Done.\n");
        defer writer.putString("Done.\n");
        defer heap.deinit();
        defer writer.putString("Deallocating heap...\n");
        writer.putString("Allocating 8 Byte str...\n");
        var str: [*]u8 = @ptrCast(heap.alloc(8));
        writer.putString("Done.\n");
        defer writer.putString("Done.\n");
        defer heap.free(@ptrCast(str), 8);
        defer writer.putString("Deallocating str...\n");
        str[0] = 'H';
        str[1] = 'e';
        str[2] = 'l';
        str[3] = 'l';
        str[4] = 'o';
        str[5] = '!';
        str[6] = '\n';
        str[7] = 0x0;
        writer.putCString(str);
    }

    for (0..256) |bus| {
        for (0..256) |slot| {
            const device = pci.checkDevice(@truncate(bus), @truncate(slot));
            if (device != 0xFFFF) {
                writer.putString("Device Found: ");
                writer.putHex(@as(u64, device));
                writer.putLn();
                writer.putString("    Vendor ID: ");
                writer.putHex(@as(u64, pci.checkVendor(@truncate(bus), @truncate(slot))));
                writer.putLn();
                writer.flush();
            }
        }
    }

    writer.flush();
    while (true) {
        cpu.cli();
        cpu.hlt();
    }
}
