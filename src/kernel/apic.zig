const cpu = @import("cpu.zig");
const IA32_APIC_BASE_MSR: usize = 0x1B;
const IA32_APIC_BASE_MSR_BSP: usize = 0x100;
const IA32_APIC_BASE_MSR_ENABLE: usize = 0x800;

pub fn getAPICBase() usize {
    return cpu.msr.read(IA32_APIC_BASE_MSR) & 0xFFFFFFFFFFFFF000;
}

fn setAPICBase(addr: usize) void {
    cpu.msr.write(IA32_APIC_BASE_MSR, (addr & 0xFFFFFFFFFFFF0000) | IA32_APIC_BASE_MSR_ENABLE);
}

pub fn enable() void {
    setAPICBase(getAPICBase());

    const newaddr: [*]volatile u32 = @ptrFromInt(getAPICBase() + 0xF0);
    newaddr[0] = newaddr[0] | 0x100;
}
