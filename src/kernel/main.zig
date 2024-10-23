const idt = @import("idt.zig");
const irq = @import("irq.zig");
const cpu = @import("cpu.zig");
const paging = @import("paging.zig");
const console = @import("console.zig");
const colors = console.Color;

// MODIFY THESE VALUES IF YOU MODIFY paging.TOTAL_ENTRIES
var PML4: [*]volatile paging.PML4Entry = @ptrFromInt(0x1000);
var PDP: [*]volatile paging.PDPEntry = @ptrFromInt(0x2000);
var PD: [*]volatile paging.PDEntry = @ptrFromInt(0x3000);
var PT: [*]volatile paging.PTEntry = @ptrFromInt(0xc0000);

export fn main() noreturn {
    paging.identityMap(PML4, 1, PDP, 1, PD, 256, PT, 512);

    // Load IRQ 32 with a function, and then load the IDT.
    idt.entry(32, @as(usize, @intFromPtr(&irq.irq32)));
    idt.load();

    // Use a writer that depends on interrupts to function.
    var writer = console.Writer.new(colors.White, colors.LightBlue);
    writer.clear();
    writer.enableCursor();
    writer.putString("Hello, World! (Using Interrupts)\n");

    // Use a writer that doesn't depend on interrupts to function.
    var raw_writer = console.RawWriter.fromWriter(writer);
    raw_writer.setColors(colors.LightMagenta, colors.LightGreen);
    raw_writer.putString("Hello, World! (Without Interrupts)\n");

    while (true) {
        cpu.cli();
        cpu.hlt();
    }
}
