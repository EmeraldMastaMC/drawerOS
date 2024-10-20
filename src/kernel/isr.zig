const irq = @import("irq.zig");
const console = @import("console.zig");

export fn print(context: irq.Frame) callconv(.C) void {
    console.putc(context.rdi, context.rsi, @truncate(context.rdx), @truncate(context.r10));
}
