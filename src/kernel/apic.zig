const cpu = @import("cpu.zig");
const pit = @import("pit.zig");
const console = @import("console.zig");
const paging = @import("paging.zig");
const main = @import("main.zig");
const allocator = @import("page_frame_allocator.zig");

pub const IA32_APIC_BASE_MSR: usize = 0x1B;
pub const IA32_APIC_BASE_MSR_BSP: usize = 0x100;
pub const IA32_APIC_BASE_MSR_ENABLE: usize = 0x800;

pub const LAPIC_ID_REGISTER: usize = 0x20; // R/W
pub const LAPIC_VERSION_REGISTER: usize = 0x30; // RO
pub const TASK_PRIORITY_REGISTER: usize = 0x80; // R/W
pub const ARBITRATION_PRIORITY_REGISTER: usize = 0x90; // RO
pub const PROCESSOR_PRIORITY_REGISTER: usize = 0xA0; // RO
pub const EOI_REGISTER: usize = 0xB0; // WO
pub const REMOTE_READ_REGISTER: usize = 0xC0; // RO
pub const LOGICAL_DESTINATION_REGISTER: usize = 0xD0; // R/W
pub const DESTINATION_FORMAT_REGISTER: usize = 0xE0; // R/W
pub const SPURIOUS_INTERRUPT_VECTOR_REGISTER: usize = 0xF0; // R/W
pub const IN_SERVICE_REGISTER: usize = 0x100; // RO, 0x100 - 0x170
pub const TRIGGER_MODE_REGISTER: usize = 0x180; // RO, 0x180 - 0x1F0
pub const INTERRUPT_REQUEST_REGISTER: usize = 0x200; // RO, 0x200 - 0x270
pub const ERROR_STATUS_REGISTER: usize = 0x280; // RO
pub const LVT_CORRECTED_MACHINE_CHECK_INTERRUPT_REGISTER: usize = 0x2F0; // R/W
pub const INTERRUPT_COMMAND_REGISTER: usize = 0x300; // R/W, 0x300 - 0x310
pub const LVT_TIMER_REGISTER: usize = 0x320; // R/W
pub const LVT_THERMAL_SENSOR_REGISTER: usize = 0x330; // R/W
pub const LVT_PERFORMANCE_MONITORING_COUNTERS_REGISTER: usize = 0x340; // R/W
pub const LVT_LINT0_REGISTER: usize = 0x350; // R/W
pub const LVT_LINT1_REGISTER: usize = 0x360; // R/W
pub const LVT_ERROR_REGISTER: usize = 0x370; // R/W

// For Timer
pub const INITIAL_COUNT_REGISTER: usize = 0x380; // R/W
pub const CURRENT_COUNT_REGISTER: usize = 0x390; // RO
pub const DIVIDE_CONFIGURATION_REGISTER: usize = 0x3E0; // R/W
pub const TIMER_MODE_ONESHOT: u32 = 0x0;
pub const TIMER_MODE_PERIODIC: u32 = 0x20000;
pub const TIMER_MODE_TSC_DEADLINE: u32 = 0x40000;
pub const TIMER_MASK: u32 = 0x10000;

pub var ticks_in_10ms: u32 = 0;
pub fn getAPICBase() usize {
    const val: u64 = (cpu.msr.read(IA32_APIC_BASE_MSR) & 0xFFFFFFFFFFFFF000) >> 12;
    return val;
}

fn setAPICBase(addr: usize) void {
    cpu.msr.write(IA32_APIC_BASE_MSR, (addr << 12) | IA32_APIC_BASE_MSR_ENABLE);
}

pub fn enable() void {
    const addr = getAPICBase();
    paging.mapPage(addr, addr, main.PML4, main.PDP, main.PD, main.PT, true, false, false, true, false, false);
    setAPICBase(addr);
    setRegister(SPURIOUS_INTERRUPT_VECTOR_REGISTER, (getRegister(SPURIOUS_INTERRUPT_VECTOR_REGISTER) & 0xFFFFFF00) | 39);
}

pub fn setRegister(offset: usize, data: u32) void {
    const addr: *volatile u32 = @ptrFromInt(getAPICBase() + offset);
    addr.* = data;
}

pub fn getRegister(offset: usize) u32 {
    const addr: *volatile u32 = @ptrFromInt(getAPICBase() + offset);
    return addr.*;
}

pub fn timerSetup(irq: u8) void {
    setRegister(LVT_TIMER_REGISTER, getRegister(LVT_TIMER_REGISTER) | TIMER_MASK);
    setRegister(LVT_TIMER_REGISTER, (getRegister(LVT_TIMER_REGISTER) & 0xFFFFFF00) | (irq + 32));
    setRegister(LVT_TIMER_REGISTER, (getRegister(LVT_TIMER_REGISTER) & 0xFFF9FFFF) | TIMER_MODE_ONESHOT);
    setRegister(DIVIDE_CONFIGURATION_REGISTER, 0x3);
}

pub fn timerInit(irq: u8) void {
    timerSetup(irq);
    pit.setFrequency(100);
    setRegister(INITIAL_COUNT_REGISTER, 0xFFFFFFFF);
    setRegister(LVT_TIMER_REGISTER, getRegister(LVT_TIMER_REGISTER) & ~TIMER_MASK);
    pit.delay(1);
    setRegister(LVT_TIMER_REGISTER, getRegister(LVT_TIMER_REGISTER) | TIMER_MASK);
    ticks_in_10ms = 0xFFFFFFFF - getRegister(CURRENT_COUNT_REGISTER);
}

pub fn sleep(ms: u32) void {
    for (0..ms) |_| {
        setRegister(INITIAL_COUNT_REGISTER, ticks_in_10ms);
        setRegister(DIVIDE_CONFIGURATION_REGISTER, 0x3);
        setRegister(LVT_TIMER_REGISTER, (getRegister(LVT_TIMER_REGISTER) & 0xFFF9FFFF) | TIMER_MODE_ONESHOT);
        setRegister(LVT_TIMER_REGISTER, getRegister(LVT_TIMER_REGISTER) & ~TIMER_MASK);
        asm volatile (
            \\ int $32
        );
        cpu.sti();
        cpu.hlt();
    }
}
