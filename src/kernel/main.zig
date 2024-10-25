const idt = @import("idt.zig");
const irq = @import("irq.zig");
const cpu = @import("cpu.zig");
const paging = @import("paging.zig");
const console = @import("console.zig");
const colors = console.Color;
const allocator = @import("page_frame_allocator.zig");
const heap_allocator = @import("heap_allocator.zig");

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
    raw_writer.putString("Identity Mapping 600MB...\n");
    // paging.identityMap(PML4, PML4_ENTRIES, PDP, PDP_ENTRIES, PD, PD_ENTRIES, PT, PT_ENTRIES);
    paging.identityMap(PML4, 1, PDP, 1, PD, 300, PT, 512);
    raw_writer.putString("Done.\n");

    // Load IRQ 32 with a function, and then load the IDT.
    raw_writer.putString("Loading Interrupt Descriptor Table...\n");
    idt.entry(32, @as(usize, @intFromPtr(&irq.irq32)));
    idt.load();
    raw_writer.putString("Done.\n");

    allocator.init();

    // Use a writer that depends on interrupts to function.
    var writer = console.Writer.fromRawWriter(raw_writer);
    writer.enableCursor();
    writer.putLn();
    writer.setColors(colors.LightGreen, colors.Black);
    writer.putString("Welcome to DrawerOS!\n");
    writer.setColors(colors.White, colors.Black);
    writer.putLn();

    var heap = heap_allocator.Heap.new(10);
    heap.init();
    writer.putHex(@intFromPtr(heap.alloc(5)));
    writer.putLn();
    writer.putHex(@intFromPtr(heap.alloc(7)));
    writer.putLn();
    writer.putHex(@intFromPtr(heap.alloc(10)));
    writer.putLn();
    // {
    //     writer.putString("Allocating Memory...\n");
    //     const string: [*]u8 = @ptrFromInt(allocator.alloc());
    //     writer.putString("Done.\n");
    //     defer writer.putString("Done.\n");
    //     defer allocator.free(@intFromPtr(string));
    //     defer writer.putString("Freeing allocated memory...\n");
    //     writer.putString("Allocated address: ");
    //     writer.putHex(@intFromPtr(string));
    //     writer.putLn();
    // }
    //
    // writer.putLn();
    //
    // {
    //     writer.putString("Allocating Memory...\n");
    //     const alloc0 = allocator.alloc();
    //     defer writer.putString("Done.\n");
    //     defer allocator.free(alloc0);
    //     defer writer.putString("Freeing allocated memory...\n");
    //     writer.putString("Done.\n");
    //     writer.putString("Allocated address: ");
    //     writer.putHex(alloc0);
    //     writer.putLn();
    //
    //     writer.putString("Allocating Memory...\n");
    //     const alloc1 = allocator.alloc();
    //     defer writer.putString("Done.\n");
    //     defer allocator.free(alloc1);
    //     defer writer.putString("Freeing allocated memory...\n");
    //     writer.putString("Done.\n");
    //     writer.putString("Allocated address: ");
    //     writer.putHex(alloc1);
    //     writer.putLn();
    // }

    while (true) {
        cpu.cli();
        cpu.hlt();
    }
}
