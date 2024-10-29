const ports = @import("ports.zig");
const CONFIG_ADDRESS: u16 = 0xCF8;
const CONFIG_DATA: u16 = 0xCFC;
const CONFIG_BAR0: u8 = 0x10;
const CONFIG_BAR1: u8 = 0x14;

// Header Type 0x0
pub const Header = struct {
    pub const Register0x0 = packed struct {
        vendor_id: u16,
        device_id: u16,
    };
    pub const Register0x1 = packed struct {
        command: u16,
        status: u16,
    };
    pub const Register0x2 = packed struct {
        revision_id: u8,
        prog_if: u8,
        subclass: u8,
        class: u8,
    };
};

pub fn configReadWord(bus: u8, slot: u8, func: u8, offset: u8) u16 {
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

pub fn configReadLong(bus: u8, slot: u8, func: u8, offset: u8) u32 {
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
pub fn configWriteLong(bus: u8, slot: u8, func: u8, offset: u8, data: u32) void {
    const lbus = @as(u32, bus);
    const lslot = @as(u32, slot);
    const lfunc = @as(u32, func);

    const address = @as(u32, (lbus << 16) | (lslot << 11) | (lfunc << 8) | (offset & 0xFC) | (@as(u32, 0x80000000)));
    ports.outl(CONFIG_ADDRESS, address);
    ports.outl(CONFIG_DATA, data);
}
pub fn getVendor(bus: u8, slot: u8) u16 {
    const vendor = configReadWord(bus, slot, 0, 0);
    return vendor;
}

pub fn getDevice(bus: u8, slot: u8) u16 {
    const device = configReadWord(bus, slot, 0, 2);
    return device;
}
pub fn getClass(bus: u8, slot: u8) u8 {
    const class = configReadWord(bus, slot, 0, 0x8 | 0x2) >> 8;
    return @truncate(class);
}

pub fn getSubClass(bus: u8, slot: u8) u8 {
    const sub_class = configReadWord(bus, slot, 0, 0x8 | 0x2) & 0xFF;
    return @truncate(sub_class);
}

pub fn getProgIf(bus: u8, slot: u8) u8 {
    const prog_if = configReadWord(bus, slot, 0, 0x8) >> 8;
    return @truncate(prog_if);
}

pub fn getBAR0(bus: u8, slot: u8) u32 {
    const bar0 = configReadLong(bus, slot, 0, CONFIG_BAR0);
    return bar0;
}

pub fn getBAR1(bus: u8, slot: u8) u32 {
    const bar1 = configReadLong(bus, slot, 0, CONFIG_BAR1);
    return bar1;
}

pub fn getBAR(bus: u8, slot: u8) usize {
    const bar0 = @as(u64, getBAR0(bus, slot));
    const bar1 = @as(u64, getBAR1(bus, slot));
    const bar = (bar1 << 32) | (bar0 & 0xFFFFFFF0);
    return bar;
}

pub fn getBARSize(bus: u8, slot: u8, bar: u64) usize {
    configWriteLong(bus, slot, 0, CONFIG_BAR0, 0xFFFFFFFF);
    const low_mask = configReadLong(bus, slot, 0, CONFIG_BAR0);
    configWriteLong(bus, slot, 0, CONFIG_BAR0, @truncate(bar & 0xFFFFFFFF));

    configWriteLong(bus, slot, 0, CONFIG_BAR1, 0xFFFFFFFF);
    const high_mask = configReadLong(bus, slot, 0, CONFIG_BAR1);
    configWriteLong(bus, slot, 0, CONFIG_BAR1, @truncate((bar & 0xFFFFFFFF00000000) >> 32));

    const size = ~((@as(u64, high_mask) << 32) | @as(u64, low_mask & 0xFFFFFFF0)) + 1;
    return size;
}
