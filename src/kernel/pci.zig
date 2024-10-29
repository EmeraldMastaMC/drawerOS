const ports = @import("ports.zig");
const CONFIG_ADDRESS: u16 = 0xCF8;
const CONFIG_DATA: u16 = 0xCFC;

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

pub fn checkVendor(bus: u8, slot: u8) u16 {
    const vendor = configReadWord(bus, slot, 0, 0);
    return vendor;
}

pub fn checkDevice(bus: u8, slot: u8) u16 {
    const device = configReadWord(bus, slot, 0, 2);
    return device;
}
