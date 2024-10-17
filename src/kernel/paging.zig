// Information on paging can be found in section 5 of the manual
// Information specific to long mode can be found in section 5.3 of the manual

const cpu = @import("cpu.zig");

pub const PML4_ENTRIES: usize = 1;
pub const PDP_ENTRIES: usize = 1;
pub const PD_ENTRIES: usize = 1;
pub const PT_ENTRIES: usize = 512;

pub const TOTAL_PML4_ENTRIES: usize = PML4_ENTRIES;
pub const TOTAL_PDP_ENTRIES: usize = PML4_ENTRIES * PDP_ENTRIES;
pub const TOTAL_PD_ENTRIES: usize = PML4_ENTRIES * PDP_ENTRIES * PD_ENTRIES;
pub const TOTAL_PT_ENTRIES: usize = PML4_ENTRIES * PDP_ENTRIES * PD_ENTRIES * PT_ENTRIES;

// For information on the stucture of PML4Entry, PDPEntry, PDEntry, and PTEntry, please refer to section 5.3.3 of the manual
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

    pub fn new(base: u64, read_write: bool, user_supervisor: bool, write_through: bool, cache_disabled: bool, available_1: u3, available_2: u11, no_execute: bool) PML4Entry {
        return PML4Entry{
            .read_write = @intFromBool(read_write),
            .user_supervisor = @intFromBool(user_supervisor),
            .write_through = @intFromBool(write_through),
            .cache_disabled = @intFromBool(cache_disabled),
            .available_1 = available_1,
            .base = @truncate(base >> 12),
            .available_2 = available_2,
            .no_execute = @intFromBool(no_execute),
        };
    }
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

    pub fn new(base: u64, read_write: bool, user_supervisor: bool, write_through: bool, cache_disabled: bool, available_1: u3, available_2: u11, no_execute: bool) PDPEntry {
        return PDPEntry{
            .read_write = @intFromBool(read_write),
            .user_supervisor = @intFromBool(user_supervisor),
            .write_through = @intFromBool(write_through),
            .cache_disabled = @intFromBool(cache_disabled),
            .available_1 = available_1,
            .base = @truncate(base >> 12),
            .available_2 = available_2,
            .no_execute = @intFromBool(no_execute),
        };
    }
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

    pub fn new(base: u64, read_write: bool, user_supervisor: bool, write_through: bool, cache_disabled: bool, available_1: u3, available_2: u11, no_execute: bool) PDEntry {
        return PDEntry{
            .read_write = @intFromBool(read_write),
            .user_supervisor = @intFromBool(user_supervisor),
            .write_through = @intFromBool(write_through),
            .cache_disabled = @intFromBool(cache_disabled),
            .available_1 = available_1,
            .base = @truncate(base >> 12),
            .available_2 = available_2,
            .no_execute = @intFromBool(no_execute),
        };
    }
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

    pub fn new(base: u64, read_write: bool, user_supervisor: bool, write_through: bool, cache_disabled: bool, global: bool, available_1: u3, available_2: u11, no_execute: bool) PTEntry {
        return PTEntry{
            .read_write = @intFromBool(read_write),
            .user_supervisor = @intFromBool(user_supervisor),
            .write_through = @intFromBool(write_through),
            .cache_disabled = @intFromBool(cache_disabled),
            .global = @intFromBool(global),
            .available_1 = available_1,
            .base = @truncate(base >> 12),
            .available_2 = available_2,
            .no_execute = @intFromBool(no_execute),
        };
    }
};

pub const CR3Entry = packed struct(u64) {
    reserved_1: u3 = 0,
    write_through: u1,
    cache_disabled: u1,
    reserved_2: u7 = 0,
    base_address: u40,
    reserved_3: u12 = 0,
};

// Loads the address of the PML4 Table into memory
pub fn load_pml4(base_address: [*]volatile PML4Entry) void {
    // Load the PML4 table into the CR3 register
    // const cr3entry = CR3Entry{
    //     .base_address = @truncate(@intFromPtr(base_address) >> 12),
    //     .write_through = 0,
    //     .cache_disabled = 0,
    // };
    cpu.cli();
    cpu.cr3.write(@bitCast(@intFromPtr(base_address)));
}

pub fn identityMap(pml4_table: [*]volatile PML4Entry, pdp_table: [*]volatile PDPEntry, pd_table: [*]volatile PDEntry, pt_table: [*]volatile PTEntry) void {
    for (0..TOTAL_PT_ENTRIES) |i| {
        pt_table[i] = PTEntry.new(i * 0x1000, true, false, false, false, false, 0, 0, false);
    }
    for (0..TOTAL_PD_ENTRIES) |i| {
        pd_table[i] = PDEntry.new(@intFromPtr(pt_table) + i * 8, true, false, false, false, 0, 0, false);
    }
    for (0..TOTAL_PDP_ENTRIES) |i| {
        pdp_table[i] = PDPEntry.new(@intFromPtr(pd_table) + i * 8, true, false, false, false, 0, 0, false);
    }
    for (0..TOTAL_PML4_ENTRIES) |i| {
        pml4_table[i] = PML4Entry.new(@intFromPtr(pdp_table) + i * 8, true, false, false, false, 0, 0, false);
    }
    load_pml4(pml4_table);
}
