const ports = @import("ports.zig");
const CONFIG_ADDRESS: u16 = 0xCF8;
const CONFIG_DATA: u16 = 0xCFC;
// Base Address Register
const CONFIG_BAR0: u8 = 0x10;
const CONFIG_BAR1: u8 = 0x14;
const BAR_TYPE_32: u8 = 0x0;
const BAR_TYPE_64: u8 = 0x2;

const OTHER_WORD: u8 = 0x2;
const REGISTER0: u8 = 0x0;
const REGISTER1: u8 = 0x4;
const REGISTER2: u8 = 0x8;
const REGISTER3: u8 = 0xC;

pub const BARType = enum {
    io_space,
    mmio32,
    mmio64,
};

// Header Type 0x0
pub const Device = struct {
    bus: u8,
    slot: u8,
    device_id: u16,
    vendor_id: u16,
    command_flags: u16,
    status: u16,
    class: u8,
    subclass: u8,
    prog_if: u8,
    revision_id: u8,
    header_type: u8,
    bar: usize,
    bar_type: BARType,
    bar_size: usize,

    pub fn new(bus: u8, slot: u8) Device {
        const vendor_id = getVendorID(bus, slot);
        const device_id = getDeviceID(bus, slot);
        const command_flags = getCommandFlags(bus, slot);
        const status = getStatus(bus, slot);
        const class = getClass(bus, slot);
        const subclass = getSubClass(bus, slot);
        const prog_if = getProgIf(bus, slot);
        const revision_id = getRevisionID(bus, slot);
        const header_type = getHeaderType(bus, slot);
        const bar = getBAR(bus, slot);
        const bar_type = getBARType(bus, slot);
        const bar_size = getBARSize(bus, slot, bar);
        return Device{
            .slot = slot,
            .bus = bus,
            .device_id = device_id,
            .vendor_id = vendor_id,
            .command_flags = command_flags,
            .status = status,
            .class = class,
            .subclass = subclass,
            .prog_if = prog_if,
            .revision_id = revision_id,
            .header_type = header_type,
            .bar = bar,
            .bar_type = bar_type,
            .bar_size = bar_size,
        };
    }
};

fn configReadWord(bus: u8, slot: u8, func: u8, offset: u8) u16 {
    const lbus = @as(u32, bus);
    const lslot = @as(u32, slot);
    const lfunc = @as(u32, func);

    // Bits 0-7: Register offset
    // Bits 8-10: Function Number
    // Bits 11-15: Device Number
    // Bits 16-23: Bus Number
    // Bits 24-30: Reserved
    // Bit 31: Enabled bit
    const address = @as(u32, (lbus << 16) | (lslot << 11) | (lfunc << 8) | (offset & 0xFC) | (@as(u32, 0x80000000)));

    ports.outl(CONFIG_ADDRESS, address);

    return @truncate((ports.inl(CONFIG_DATA) >> @truncate(((offset & 2) * 8))) & 0xFFFF);
}

fn configReadLong(bus: u8, slot: u8, func: u8, offset: u8) u32 {
    const lbus = @as(u32, bus);
    const lslot = @as(u32, slot);
    const lfunc = @as(u32, func);

    // Bits 0-7: Register offset
    // Bits 8-10: Function Number
    // Bits 11-15: Device Number
    // Bits 16-23: Bus Number
    // Bits 24-30: Reserved
    // Bit 31: Enabled bit
    const address = @as(u32, (lbus << 16) | (lslot << 11) | (lfunc << 8) | (offset & 0xFC) | (@as(u32, 0x80000000)));

    ports.outl(CONFIG_ADDRESS, address);

    return ports.inl(CONFIG_DATA);
}

fn configWriteLong(bus: u8, slot: u8, func: u8, offset: u8, data: u32) void {
    const lbus = @as(u32, bus);
    const lslot = @as(u32, slot);
    const lfunc = @as(u32, func);

    const address = @as(u32, (lbus << 16) | (lslot << 11) | (lfunc << 8) | (offset & 0xFC) | (@as(u32, 0x80000000)));
    ports.outl(CONFIG_ADDRESS, address);
    ports.outl(CONFIG_DATA, data);
}

pub fn deviceExists(bus: u8, slot: u8) bool {
    if (getVendorID(bus, slot) == 0xFFFF) {
        return false;
    }
    return true;
}
pub fn getVendorID(bus: u8, slot: u8) u16 {
    const vendor = configReadWord(bus, slot, 0, REGISTER0);
    return vendor;
}

pub fn getDeviceID(bus: u8, slot: u8) u16 {
    const device = configReadWord(bus, slot, 0, REGISTER0 | OTHER_WORD);
    return device;
}

pub fn getCommandFlags(bus: u8, slot: u8) u16 {
    const command_flags = configReadWord(bus, slot, 0, REGISTER1);
    return command_flags;
}

pub fn getStatus(bus: u8, slot: u8) u16 {
    const status = configReadWord(bus, slot, 0, REGISTER1 | OTHER_WORD);
    return status;
}

pub fn getClass(bus: u8, slot: u8) u8 {
    const class = configReadWord(bus, slot, 0, REGISTER2 | OTHER_WORD) >> 8;
    return @truncate(class);
}

pub fn getSubClass(bus: u8, slot: u8) u8 {
    const sub_class = configReadWord(bus, slot, 0, REGISTER2 | OTHER_WORD) & 0xFF;
    return @truncate(sub_class);
}

pub fn getProgIf(bus: u8, slot: u8) u8 {
    const prog_if = configReadWord(bus, slot, 0, REGISTER2) >> 8;
    return @truncate(prog_if);
}

pub fn getRevisionID(bus: u8, slot: u8) u8 {
    const revision_id = configReadWord(bus, slot, 0, REGISTER2) & 0xFF;
    return @truncate(revision_id);
}

pub fn getHeaderType(bus: u8, slot: u8) u8 {
    const header_type = configReadWord(bus, slot, 0, REGISTER3 | OTHER_WORD) & 0xFF;
    return @truncate(header_type);
}

pub fn getBAR0(bus: u8, slot: u8) u32 {
    const bar0 = configReadLong(bus, slot, 0, CONFIG_BAR0);
    return bar0;
}

pub fn getBAR1(bus: u8, slot: u8) u32 {
    const bar1 = configReadLong(bus, slot, 0, CONFIG_BAR1);
    return bar1;
}

pub fn getBARType(bus: u8, slot: u8) BARType {
    const bar = getBAR0(bus, slot);
    if ((bar & 0x1) == 0x1) {
        return BARType.io_space;
    } else if ((bar & 0x4) == 0x4) {
        return BARType.mmio64;
    } else {
        return BARType.mmio32;
    }
}

pub fn getBAR(bus: u8, slot: u8) usize {
    var bar: u64 = undefined;
    const bar_type = getBARType(bus, slot);
    if (bar_type == BARType.mmio64) {
        const bar0 = @as(u64, getBAR0(bus, slot));
        const bar1 = @as(u64, getBAR1(bus, slot));
        bar = (bar1 << 32) | (bar0 & 0xFFFFFFF0);
    } else if (bar_type == BARType.mmio32) {
        bar = @as(u64, getBAR0(bus, slot) & 0xFFFFFFF0);
    } else {
        bar = @as(u64, getBAR0(bus, slot) & 0xFFFFFFFC);
    }
    return bar;
}

pub fn getBARSize(bus: u8, slot: u8, bar: u64) usize {
    const bar_type = getBARType(bus, slot);
    if (bar_type == BARType.mmio64) {
        configWriteLong(bus, slot, 0, CONFIG_BAR0, 0xFFFFFFFF);
        const low_mask = configReadLong(bus, slot, 0, CONFIG_BAR0);
        configWriteLong(bus, slot, 0, CONFIG_BAR0, @truncate(bar & 0xFFFFFFFF));

        configWriteLong(bus, slot, 0, CONFIG_BAR1, 0xFFFFFFFF);
        const high_mask = configReadLong(bus, slot, 0, CONFIG_BAR1);
        configWriteLong(bus, slot, 0, CONFIG_BAR1, @truncate((bar & 0xFFFFFFFF00000000) >> 32));

        const size = ~((@as(u64, high_mask) << 32) | @as(u64, low_mask & 0xFFFFFFF0)) + 1;
        return size;
    } else if (bar_type == BARType.mmio32) {
        configWriteLong(bus, slot, 0, CONFIG_BAR0, 0xFFFFFFFF);
        const mask = configReadLong(bus, slot, 0, CONFIG_BAR0);
        configWriteLong(bus, slot, 0, CONFIG_BAR0, @truncate(bar & 0xFFFFFFFF));

        return ~(@as(u64, mask) | 0xFFFFFFFF00000000) + 1;
    } else {
        configWriteLong(bus, slot, 0, CONFIG_BAR0, 0xFFFFFFFF);
        const mask = configReadLong(bus, slot, 0, CONFIG_BAR0);
        configWriteLong(bus, slot, 0, CONFIG_BAR0, @truncate(bar & 0xFFFFFFFF));

        return ~(@as(u64, mask) | 0xFFFFFFFF00000000) + 1;
    }
}
