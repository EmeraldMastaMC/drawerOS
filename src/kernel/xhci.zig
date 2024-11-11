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
    rtsoff: RuntimeRegisterOffset,

    // Host Controller Capability Parameters 2
    hccparams2: HccParams2,
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
const RuntimeRegisterOffset = packed struct {
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

// Host Controller Operational Registers
const OperationalRegisters = packed struct {
    // USB Command (USBCMD)
    usbcmd: UsbCommand,

    // USB Status (USBSTS)
    usbsts: UsbStatus,

    // Page Size (PAGESIZE)
    pagesize: PageSize,

    // Reserved
    resv0: u64, // RO

    // Device Notification Control (DNCTRL)
    dnctrl: DeviceNotificationControl,

    // Command Ring Control
    crcr: CommandRingControl,

    // Reserved
    resv1: [2]u64,

    // Device Context Base Address Array Pointer
    dcbaap: DeviceContextBaseAddressArray,

    // Configure (CONFIG)
    config: Configure,

    // Reserved
    resv2: [241]u32,

    // Port Register Set(s)
    // Not all of this space will be used, which means that this space WILL OVERLAP WITH OTHER STRUCTS, the true size of this array is MaxPorts
    port_register_sets: [256]PortRegisterSet, // Change this
};

const UsbCommand = packed struct {
    // Run/Stop (RS)
    rs: bool, // R/W

    // Host Controller Reset (HCRST)
    hcrst: bool, // R/W

    // Interrupter Enable (INTE)
    inte: bool, // R/W

    // Host System Error Enable (HSEE)
    hsee: bool, // R/W

    // Reserved and Preserved
    resvpresv0: u3, // R/W

    // Light Host Controller Reset (LHCRST)
    lhcrst: bool, // R/W / RO

    // Controller Save State (CSS)
    css: bool, // R/W

    // Controller Restore State (CRS)
    crs: bool, // R/W

    // Enable Wrap Event (EWE)
    ewe: bool, // R/W

    // Enable U3 MFINDEX Stop (UE3S)
    ue3s: bool, // R/W

    // Stopped Short Packet Enable (SPE)
    spe: bool, // R/W

    // CEM Enable (CME)
    cme: bool, // R/W

    // Reserved and Preserved
    resvpresv1: u18,
};

const UsbStatus = packed struct {
    // Host Controller Halted
    hch: bool, // RO

    // Reserved and Preserved
    resvpresv0: bool, // R/W

    // Host System Error (HSE)
    hse: bool, // R/WC

    // Event Interrupt (EINT)
    eint: bool, // R/WC

    // Port Change Detected (PCD)
    pcd: bool, // R/WC

    // Reserved and Zero'd (write zeros to this field)
    resvzrd: u3, // R/W

    // Save State Status (SSS)
    sss: bool, // RO

    // Restore State Status (RSS)
    rss: bool, // RO

    // Save/Restore Error (SRE)
    sre: bool, // R/WC

    // Controller Not Ready (CNR)
    cnr: bool, // RO

    // Host Controller Error (HCE)
    hce: bool, // RO

    // Reserved and Preserved
    resvpresv1: u19,
};

const PageSize = packed struct {
    // Paage Size
    // Actual Page Size = page_size << 12
    page_size: u16, // RO

    // Reserved
    resv: u16, // RO
};

const DeviceNotificationControl = packed struct {
    // Notification Enable 0 (N0)
    n0: bool, // R/W

    // Notification Enable 1 (N1)
    n1: bool, // R/W

    // Notification Enable 2 (N2)
    n2: bool, // R/W

    // Notification Enable 3 (N3)
    n3: bool, // R/W

    // Notification Enable 4 (N4)
    n4: bool, // R/W

    // Notification Enable 5 (N5)
    n5: bool, // R/W

    // Notification Enable 6 (N6)
    n6: bool, // R/W

    // Notification Enable 7 (N7)
    n7: bool, // R/W

    // Notification Enable 8 (N8)
    n8: bool, // R/W

    // Notification Enable 9 (N9)
    n9: bool, // R/W

    // Notification Enable 10 (N10)
    n10: bool, // R/W

    // Notification Enable 11 (N11)
    n11: bool, // R/W

    // Notification Enable 12 (N12)
    n12: bool, // R/W

    // Notification Enable 13 (N13)
    n13: bool, // R/W

    // Notification Enable 14 (N14)
    n14: bool, // R/W

    // Notification Enable 15 (N15)
    n15: bool, // R/W

    // Reserved and Preserved
    resvpresv: u16, // RO
};

const CommandRingControl = packed struct {
    // Ring Cycle State (RCS)
    rcs: bool, // R/W

    // Command Stop (CS)
    cs: bool, // R/WC

    // Command Abort (CA)
    ca: bool, // R/WC

    // Command Ring Running (CRR)
    crr: bool, // RO

    // Reserved and Preserved
    resvpresv: u2, // R/W

    // Command Ring Pointer
    // Actual Pointer = crp << 6
    crp: u58, // R/W
};

const DeviceContextBaseAddressArray = packed struct {
    // Reserved and Zero'd
    resvzrd: u6, // R/W

    // Device Context Base Address Array Pointer
    dev_context_base_addr_arr_pointer: u58, // R/W
};

const Configure = packed struct {
    // Max Device Slots Enabled (MaxSlotsEn)
    max_slots_en: u8, // R/W

    // U3 Entry Enable (U3E)
    u3e: bool, // R/W

    // Configuration Information Enable (CIE)
    cie: bool, // R/W

    // Reserved and Preserved
    resvpresv: u22, // R/W
};

const PortRegisterSet = packed struct {
    // Port Status and Control (PORTSC)
    portsc: u32,

    // Port Power Management Status and Control (PORTPMSC)
    portpmsc: u32,

    // Port Link Info (PORTLI)
    portli: u32,

    // Port Hardware LPM Control (PORTHLPMC)
    porthlpmc: u32,
};

const PortStatusControl = packed struct {
    // Current Connect Status (bit is zero, no matter the connect status, if port_power is 0)
    current_connect_status: bool, // RO

    // Port Enabled/Disabled (bit is zero, no matter the connect status, if port_power is 0)
    port_enabled_disabled: bool, // R/WC

    // Reserved and Zero'd
    resvzrd0: bool, // R/W

    // Over-Current Active
    over_current_active: bool, // RO

    // Port Reset (bit is zero, no matter the connect status, if port_power is 0)
    port_reset: bool, // R/W

    // Port Link State (bits are zero, no matter the connect status, if port_power is 0)
    port_link_state: u4, // R/W

    // Port Power
    port_power: bool, // R/W

    // Port Speed
    port_speed: PortSpeed, // RO

    // Port Indicator Control (bits are zero, no matter the connect status, if port_power is 0)
    port_indicator_control: PortIndicatorControl, // R/W

    // Port Link State Write Strobe (bit is zero, no matter the connect status, if port_power is 0)
    port_link_state_write_strobe: bool, // R/W

    // Connect Status Change (bit is zero, no matter the connect status, if port_power is 0)
    connect_status_change: bool, // R/WC

    // Port Enable/Disable Change (bit is zero, no matter the connect status, if port_power is 0)
    port_enable_disable_change: bool, // R/WC

    // Warm Port Reset Change (Reserved and Zero'd on USB 2.0 ports) (bit is zero, no matter the connect status, if port_power is 0)
    warm_port_reset_change: bool, // R/WC

    // Over-current Change (bit is zero, no matter the connect status, if port_power is 0)
    over_current_change: bool, // R/WC

    // Port Reset Change (bit is zero, no matter the connect status, if port_power is 0)
    port_reset_change: bool, // R/WC

    // Port Line State Change (bit is zero, no matter the connect status, if port_power is 0)
    port_line_state_change: bool, // R/WC

    // Port Config Error Change (Reserved and Zero'd on USB 2.0 ports) (bit is zero, no matter the connect status, if port_power is 0)
    port_config_error_change: bool, // R/WC

    // Cold Attach Status (Reserved and Zero'd on USB 2.0 ports) (bit is zero, no matter the connect status, if port_power is 0)
    cold_attach_status: bool, // RO

    // Wake on Connect Enable
    wake_on_connect_enable: bool, // R/W

    // Wake on Disconnect Enable
    wake_on_disconnect_enable: bool, // R/W

    // Wake on Over-current Enable
    wake_on_overcurrent_enable: bool, // R/W

    // Reserved and Zero'd
    resvzrd: u2, // R/W

    // Device Removable
    device_removable: bool, // RO

    // Warm Port Reset (Reserved and Zero'd on USB 2.0 ports)
    warm_port_reset: bool, // R/WC
};

const PortSpeed = enum(u4) {
    undefined0 = 0,
    full_speed = 1, // USB 2.0, 12 MB/s
    low_speed = 2, // USB 2.0, 1.5 Mb/s
    high_speed = 3, // USB 2.0, 480Mb/s
    super_speed = 4, // USB 3.0, 5Gb/s
    undefined1 = 5,
    undefined2 = 6,
    undefined3 = 7,
    undefined4 = 8,
    undefined5 = 9,
    undefined6 = 10,
    undefined7 = 11,
    undefined8 = 12,
    undefined9 = 13,
    undefined10 = 14,
    undefined11 = 15,
};

const PortIndicatorControl = enum(u2) {
    port_indicators_off = 0,
    amber = 1,
    green = 2,
    undefined0 = 3,
};
