// Information on paging can be found in section 5 of the manual
// Information specific to long mode can be found in section 5.3 of the manual

const cpu = @import("cpu.zig");

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
    const cr3entry = CR3Entry{
        .base_address = @truncate(@intFromPtr(base_address) >> 12),
        .write_through = 0,
        .cache_disabled = 0,
    };
    cpu.cli();
    cpu.cr3.write(@bitCast(cr3entry));
}

pub fn identityMap(pml4_table: [*]volatile PML4Entry, pml4_entries: usize, pdp_table: [*]volatile PDPEntry, pdp_entries: usize, pd_table: [*]volatile PDEntry, pd_entries: usize, pt_table: [*]volatile PTEntry, pt_entries: usize) void {
    const total_pml4_entries: usize = pml4_entries;
    const total_pdp_entries: usize = pml4_entries * pdp_entries;
    const total_pd_entries: usize = pml4_entries * pdp_entries * pd_entries;
    const total_pt_entries: usize = pml4_entries * pdp_entries * pd_entries * pt_entries;
    for (0..total_pt_entries) |i| {
        pt_table[i] = PTEntry.new(i * 0x1000, true, false, false, false, false, 0, 0, false);
    }
    for (0..total_pd_entries) |i| {
        pd_table[i] = PDEntry.new(@intFromPtr(pt_table) + i * 8 * 512, true, false, false, false, 0, 0, false);
    }
    for (0..total_pdp_entries) |i| {
        pdp_table[i] = PDPEntry.new(@intFromPtr(pd_table) + i * 8 * 512, true, false, false, false, 0, 0, false);
    }
    for (0..total_pml4_entries) |i| {
        pml4_table[i] = PML4Entry.new(@intFromPtr(pdp_table) + i * 8 * 512, true, false, false, false, 0, 0, false);
    }
    load_pml4(pml4_table);
}

pub fn mapPage(phys_addr: *void, virtual_addr: *void, pml4_table: [*]volatile PML4Entry, pdp_table: [*]volatile PDPEntry, pd_table: [*]volatile PDEntry, pt_table: [*]volatile PTEntry, read_write: bool, user_supervisor: bool, write_through: bool, cache_disabled: bool, global: bool, no_execute: bool) void {

    // See figure 5-17 in the manual
    const pml4_index = (@intFromPtr(virtual_addr) >> 39) & 0x1FF;
    const pdp_index = (@intFromPtr(virtual_addr) >> 30) & 0x1FF;
    const pd_index = (@intFromPtr(virtual_addr) >> 21) & 0x1FF;
    const pt_index = (@intFromPtr(virtual_addr) >> 12) & 0x1FF;

    if (pml4_table[pml4_index].base == 0) {
        pml4_table[pml4_index] = PML4Entry.new(@intFromPtr(pdp_table) + pml4_index * 8, true, false, false, false, 0, 0, false);
    }
    if (pdp_table[(pml4_index * 512) + pdp_index].base == 0) {
        pdp_table[(pml4_index * 512) + pdp_index] = PDPEntry.new(@intFromPtr(pd_table) + pdp_index * 8, true, false, false, false, 0, 0, false);
    }
    if (pd_table[(pml4_index * 512 * 512) + (pdp_index * 512) + pd_index].base == 0) {
        pd_table[(pml4_index * 512 * 512) + (pdp_index * 512) + pd_index] = PDEntry.new(@intFromPtr(pt_table) + pd_index * 8, true, false, false, false, 0, 0, false);
    }

    pt_table[(pml4_index * 512 * 512 * 512) + (pdp_index * 512 * 512) + (pd_index * 512) + pt_index] = PTEntry.new(@intFromPtr(phys_addr), read_write, user_supervisor, write_through, cache_disabled, global, 0, 0, no_execute);
}
