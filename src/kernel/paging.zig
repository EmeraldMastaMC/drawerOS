// Page Map Level 4 (PML4) Table Entry
const PML4Entry = packed struct(u64) {
    present: u1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    nx: u1,
};

// Page Directory Pointer (PDP) Table Entry
const PDPEntry = packed struct(u64) {
    present: u1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    nx: u1,
};

// Page Directory (PD) Table Entry
const PDEntry = packed struct(u64) {
    present: u1,
    read_write: u1,
    user_supervisor: u1,
    write_through: u1,
    cache_disabled: u1,
    accessed: u1 = 0,
    reserved: u3 = 0,
    available_1: u3,
    base: u40,
    available_2: u11,
    nx: u1,
};

// Page Table (PT) Entry
const PTEntry = packed struct(u64) {
    present: u1,
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
    nx: u1,
};
