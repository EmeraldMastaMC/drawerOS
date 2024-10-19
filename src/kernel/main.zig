const idt = @import("idt.zig");
const irq = @import("irq.zig");
const cpu = @import("cpu.zig");
const paging = @import("paging.zig");

extern fn isr0() align(8) callconv(.Naked) void;

// MODIFY THESE VALUES IF YOU MODIFY paging.TOTAL_ENTRIES
var PML4: [*]volatile paging.PML4Entry = @ptrFromInt(0x1000);
var PDP: [*]volatile paging.PDPEntry = @ptrFromInt(0x2000);
var PD: [*]volatile paging.PDEntry = @ptrFromInt(0x3000);
var PT: [*]volatile paging.PTEntry = @ptrFromInt(0x4000);

export fn main() noreturn {
    paging.identityMap(PML4, PDP, PD, PT);

    idt.entry(32, @as(usize, @intFromPtr(&irq.irq32)));
    idt.load();

    // Test our putChar interrupt
    asm volatile (
    // column
        \\ mov $39, %rdi
        // row
        \\ mov $12, %rsi
        // Color
        \\ mov $0xDB, %rdx
        // Character
        \\ mov $'A', %r10
        // putChar Interrupt
        \\ int $32
    );

    while (true) {}
}
