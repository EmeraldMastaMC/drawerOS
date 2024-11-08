// https://www.intel.com/content/dam/www/public/us/en/documents/technical-specifications/extensible-host-controler-interface-usb-xhci.pdf
// TODO investigate page 9-8 and M-7 in USB: The Universal Serial Bus by Benjamin David Lunt Third Edition
const pci = @import("pci.zig");
const page_allocator = @import("page_frame_allocator.zig");
const paging = @import("paging.zig");

// Host Controller Capability Registers
const CapabilityRegisters = packed struct {
    // Length of Capability Registers
    caplength: u8, // RO

    // Reserved
    resv: u8, // RO

    // Host Controller Interface Version Number
    hciversion: u16, // RO

    // Host Controller Structural Parameters 1
    hcsparams1: HcsParams1, // RO

    // Host Controller Structural Parameters 2
    hcsparams2: HcsParams2, // RO

    // Host Controller Structural Parameters 3
    hcsparams3: HcsParams3, // RO

    // Host Controller Capability Parameters 1
    hccparams1: HccParams1,

    // Doorbell Offset
    dboff: DoorbellOffset,

    // Runtime Register Space Offset
    rtsoff: u32,

    // Host Controller Capability Parameters 2
    hccparams2: u32,
};

// Host Controller Structural Parameters 1
const HcsParams1 = packed struct {
    // Number of Device Slots (MaxSlots)
    max_slots: u8, // RO

    // Number of Interrupters (MaxIntrs)
    max_intrs: u11, // RO

    // Reserved
    resv: u5, // RO

    // Number of Ports (MaxPorts)
    max_ports: u8, // RO

};

// Host Controller Structural Parameters 2
const HcsParams2 = packed struct {
    // Isochronous Scheduling Threshold (IST)
    ist: u4, // RO

    // Event Ring Segment Table Max (ERST Max)
    erst_max: u4, // RO

    // Reserved
    resv: u13, // RO

    // Max Scratchpad Buffers (High 5 bits)
    msb_hi: u5, // RO

    // Scratchpad Restore (SPR)
    spr: bool, // RO

    // Max Scratchpad Buffers (Low 5 bits)
    msb_lo: u5, // RO

};

// Host Controller Structural Parameters 3
const HcsParams3 = packed struct {
    // U1 Device Exit Latency
    u1_del: u8, // RO

    // Reserved
    resv: u8, // RO

    // U2 Device Exit Latency
    u2_del: u16,
};

// Host Controller Capability Parameters 1
const HccParams1 = packed struct {
    // 64-bit Addressing Cability (AC64)
    ac64: bool, // RO

    // Bandwidth Negotiation Capability (BNC)
    bnc: bool, // RO

    // Context Size (CSZ)
    csz: bool, // RO

    // Port Power Control (PPC)
    ppc: bool, // RO

    // Port Indicators (PIND)
    pind: bool, // RO

    // Light Host Controller Reset Capability (LHRC)
    lhrc: bool, // RO

    // Latency Tolerance Messaging Capability (LTC)
    ltc: bool, // RO

    // No Secondary Stream ID Support (NSS)
    nss: bool, // RO

    // Parse All Event Data (PAE)
    pae: bool, // RO

    // Stopped - Short Packet Capability (SPC)
    spc: bool, // RO

    // Stopped EDTLA Capability (SEC)
    sec: bool, // RO

    // Continuous Frame ID Capability (CFC)
    cfc: bool, // RO

    // Maximum Primary Stream Array Size (MaxPSASize)
    // Max Primary Stream Array Size is actually 2^(MaxPSASize+1)
    max_psa_size: u4, // RO

    // xHCI Extended Capabilities Pointer (xECP)
    // It is the offset in 32-bit dwords from the I/O Base of the Capability Register.
    // Offset in bytes is xECP * 4
    xecp: u16, // RO
};

// Doorbell Offset Register
const DoorbellOffset = packed struct {
    // Reserved
    resv: u2, // RO

    // Doorbell Array Offset
    // Doorbell Array Offset = (dao << 2)
    dao: u30, // RO
};

// Runtime Register Base Offset Register
const RuntimeRegister = packed struct {
    // Reserved
    resv: u5, // RO

    // Runtime Register Space Offset
    rrso: u27, // RO
};

// Host Controller Capability Parameters 2
const HccParams2 = packed struct {
    // U3 Entry Capability (U3C)
    u3c: bool, // RO

    // ConfigEP Command Max Exit Latency Too Large (CMC)
    cmc: bool, // RO

    // Foce Save Context Capability (FSC)
    fsc: bool, // RO

    // Compliance Transition Capability (CTC)
    ctc: bool, // RO

    // Large ESIT Payload Capability (LEC)
    lec: bool, // RO

    // Configuration Information Capability (CIC)
    cic: bool, // RO

    // Reserved
    resv: u26, // RO
};
