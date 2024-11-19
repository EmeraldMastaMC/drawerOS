const irq = @import("irq.zig");
const apic = @import("apic.zig");
const pit = @import("pit.zig");
const console = @import("console.zig");
const allocator = @import("page_frame_allocator.zig");

export fn print(context: irq.Frame) callconv(.C) void {
    console.putc(context.rdi, context.rsi, @truncate(context.rdx), @truncate(context.r10));
}

export fn printirqnum(context: irq.Frame) callconv(.C) void {
    var writer = console.RawWriter.new(console.Color.White, console.Color.Black);
    writer.putHexByte(@truncate(context.rax & 0xFF));
}
