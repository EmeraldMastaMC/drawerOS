const irq = @import("irq.zig");
const console = @import("console.zig");

export fn print(context: irq.Frame) callconv(.C) void {
    console.printChar(context.rdi, context.rsi, @truncate(context.rdx), @truncate(context.r10));
}
