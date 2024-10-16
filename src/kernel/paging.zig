// Information on paging can be found in section 5 of the manual
// Information specific to long mode can be found in section 5.3 of the manual

const cpu = @import("cpu.zig");

// Page Map Level 4 (PML4) Table Entry
pub const PML4Entry = packed struct(u64) {
    present: u1 = 1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    no_execute: u1,
};

// Page Directory Pointer (PDP) Table Entry
pub const PDPEntry = packed struct(u64) {
    present: u1 = 1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    no_execute: u1,
};

// Page Directory (PD) Table Entry
pub const PDEntry = packed struct(u64) {
    present: u1 = 1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    no_execute: u1,
};

// Page Table (PT) Entry
pub const PTEntry = packed struct(u64) {
    present: u1 = 1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    dirty: u1 = 0,
    pat: u1 = 0, // Page Attribute Table
    global: u1,
    available_1: u3,
    base: u40,
    available_2: u11,
    no_execute: u1,
};

// Explain the PWT bit
pub const CR3Entry = packed struct(u64) {
    reserved_1: u3 = 0,
    write_through: u1,
    cache_disabled: u1,
    reserved_2: u7 = 0,
    base_address: u40,
    reserved_3: u12 = 0,
};

// Loads the address of the PML4 Table into memory
pub fn load_pml4(base_address: *PML4Entry) void {
    // Load the PML4 table into the CR3 register
    const cr3entry = CR3Entry{
        .base_address = @truncate(@intFromPtr(base_address) >> 12),
        .write_through = 0,
        .cache_disabled = 0,
    };
    cpu.cr3.write(@bitCast(cr3entry));
}
