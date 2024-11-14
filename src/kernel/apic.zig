const cpu = @import("cpu.zig");

const IA32_APIC_BASE_MSR: usize = 0x1B;
const IA32_APIC_BASE_MSR_BSP: usize = 0x100;
const IA32_APIC_BASE_MSR_ENABLE: usize = 0x800;

const LAPIC_ID_REGISTER: usize = 0x20; // R/W
const LAPIC_VERSION_REGISTER: usize = 0x30; // RO
const TASK_PRIORITY_REGISTER: usize = 0x80; // R/W
const ARBITRATION_PRIORITY_REGISTER: usize = 0x90; // RO
const PROCESSOR_PRIORITY_REGISTER: usize = 0xA0; // RO
const EOI_REGISTER: usize = 0xB0; // WO
const REMOTE_READ_REGISTER: usize = 0xC0; // RO
const LOGICAL_DESTINATION_REGISTER: usize = 0xD0; // R/W
const DESTINATION_FORMAT_REGISTER: usize = 0xE0; // R/W
const SPURIOUS_INTERRUPT_VECTOR_REGISTER: usize = 0xF0; // R/W
const IN_SERVICE_REGISTER: usize = 0x100; // RO, 0x100 - 0x170
const TRIGGER_MODE_REGISTER: usize = 0x180; // RO, 0x180 - 0x1F0
const INTERRUPT_REQUEST_REGISTER: usize = 0x200; // RO, 0x200 - 0x270
const ERROR_STATUS_REGISTER: usize = 0x280; // RO
const LVT_CORRECTED_MACHINE_CHECK_INTERRUPT_REGISTER: usize = 0x2F0; // R/W
const INTERRUPT_COMMAND_REGISTER: usize = 0x300; // R/W, 0x300 - 0x310
const LVT_TIMER_REGISTER: usize = 0x320; // R/W
const LVT_THERMAL_SENSOR_REGISTER: usize = 0x330; // R/W
const LVT_PERFORMANCE_MONITORING_COUNTERS_REGISTER: usize = 0x340; // R/W
const LVT_LINT0_REGISTER: usize = 0x350; // R/W
const LVT_LINT1_REGISTER: usize = 0x360; // R/W
const LVT_ERROR_REGISTER: usize = 0x370; // R/W

// For Timer
const INTIAL_COUNT_REGISTER: usize = 0x380; // R/W
const CURRENT_COUNT_REGISTER: usize = 0x390; // RO
const DIVIDE_CONFIGURATION_REGISTER: usize = 0x3E0; // R/W

pub fn getAPICBase() usize {
    return cpu.msr.read(IA32_APIC_BASE_MSR) & 0xFFFFFFFFFFFFF000;
}

fn setAPICBase(addr: usize) void {
    cpu.msr.write(IA32_APIC_BASE_MSR, (addr & 0xFFFFFFFFFFFF0000) | IA32_APIC_BASE_MSR_ENABLE);
}

pub fn enable() void {
    setAPICBase(getAPICBase());
    setRegister(getRegister(SPURIOUS_INTERRUPT_VECTOR_REGISTER) | 0x1FF);
}

pub fn setRegister(offset: usize, data: u32) void {
    const addr: *volatile u32 = @ptrFromInt(getAPICBase() + offset);
    addr.* = data;
}

pub fn getRegister(offset: usize) void {
    const addr: *volatile u32 = @ptrFromInt(getAPICBase() + offset);
    return addr.*;
}

export fn eoi() void {
    setRegister(EOI_REGISTER, 0);
}
