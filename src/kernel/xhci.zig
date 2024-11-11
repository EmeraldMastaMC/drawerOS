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
    portsc: PortStatusControl,

    // Port Power Management Status and Control (PORTPMSC)
    portpmsc: PowerManagementPortStatusControl,

    // Port Link Info (PORTLI)
    portli: PortLinkInformation,

    // Port Hardware LPM Control (PORTHLPMC)
    porthlpmc: PortHardwareLPMControl,
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

const PowerManagementPortStatusControlUSB2 = packed struct {
    // L1 Status
    l1_status: L1Status, // RO

    // Remote Wake Enable
    remote_wake_enable: bool, // R/W

    // Host Initiated Resume Duration
    // Real duration is host_initiated_resume_duration * 75 + 50
    host_initiated_resume_duration: u4, // R/W

    // L1 Device Slot
    l1_device_slot: u8, // R/W

    // Hardware LPM Enable
    hardware_lpm_enable: bool, // R/W

    // Reserved and Preserved
    resvpresv: u11, // R/W

    // Port Test Control
    port_test_control: u4, // R/W
};

const L1Status = enum(u3) {
    invalid = 0,
    success = 1,
    not_yet = 2,
    not_supported = 3,
    timeout_error = 4,
    resv0 = 5,
    resv1 = 6,
    resv2 = 7,
};

const PowerManagementPortStatusControlUSB3 = packed struct {
    // U1 Timeout
    u1_timeout: u8, // R/W

    // U2 Timeout
    u2_timeout: u8, // R/W

    // Force Link PM Accept
    force_link_pm_accept: bool, // R/W

    // Reserved and Preserved
    resvpresv: u15, // R/W
};

const PowerManagementPortStatusControl = packed union {
    usb2: PowerManagementPortStatusControlUSB2,
    usb3: PowerManagementPortStatusControlUSB3,
};

const PortLinkInformationUSB2 = packed struct {
    // Reserved and Preserved
    resvpresv: u32, // R/W
};

const PortLinkInformationUSB3 = packed struct {
    // Link Error Count
    link_error_count: u16, // RO

    // Rx Lane Count (RLC)
    rlc: u4, // RO

    // Tx Lane Count (TLC)
    tlc: u4, // RO

    // Reserved and Preserved
    resvpresv: u8, // R/W
};

const PortLinkInformation = packed union {
    usb2: PortLinkInformationUSB2,
    usb3: PortLinkInformationUSB3,
};

const PortHardwareLPMControlUSB2 = packed struct {
    // Host Initiated Resume Duration Mode (HIRDM)
    hirdm: u2, // RWS

    // L1 Timeout
    // Real Timeout calculated by l1_timeout * 256 microsecond
    l1_timeout: u8, // RWS

    // Best Effort Service Latency Deep (BESLD)
    besld: u4, // RWS

    // Reserved and Preserved
    resvpresv: u18, // R/W
};

const PortHardwareLPMControlUSB3 = packed struct {
    // Reserved and Preserved
    resvpresv: u32, // R/W
};

const PortHardwareLPMControl = packed union {
    usb2: PortHardwareLPMControlUSB2,
    usb3: PortHardwareLPMControlUSB3,
};

const HostRuntimeRegisterSet = packed struct {
    // Microframe Index Register
    microframe_index_register: u32,

    // Reserved and Zero'd
    resvzrd: [28]u8,

    // Interrupter Register Sets 0-1023
    // Actual Size Varies, so this array will overlap with other structs, BE CAREFUL
    // Actual size is HcsParams1.max_intrs
    interrupter_register_sets: [1024]InterrupterRegisterSet,
};

const InterrupterRegisterSet = packed struct {
    // Interrupter Management Register
    interrupter_management_register: InterrupterManagement, // R/W

    // Interrupter Moderation
    interrupter_moderation: InterrupterModeration, // R/W

    // Event Ring Segment Table Size
    event_ring_segment_table_size: EventRingSegmentTableSize, // R/W

    // Reserved and Preserved
    resvpresv: u32, // R/W

    // Event Ring Segment Table Base Address
    event_ring_segment_table_base_address: EventRingSegmentTableBaseAddress, // R/W

    // Event Ring Dequeue Pointer
    event_ring_dequeue_pointer: u64, // R/W
};

const InterrupterManagement = packed struct {
    // Interrupt Pending (IP)
    ip: bool, // R/WC

    // Interrupt Enable
    interrupt_enable: bool, // R/W

    // Reserved and Preserved
    resvpresv: u30, // R/W
};

const InterrupterModeration = packed struct {
    // Interrupt Moderation Interval
    // Interrupts per second = 1 / (250*10^(-9) * interrupt_moderation_interval)
    interrupt_moderation_interval: u16, // R/W

    // Interrupt Moderation Counter
    interrupt_moderation_counter: u16, // R/W
};

const EventRingSegmentTableSize = packed struct {
    // Event Ring Segment Table Size
    event_ring_segment_table_size: u16, // R/W

    // Reserved and Preserved
    resvpresv: u16, // R/W
};

const EventRingSegmentTableBaseAddress = packed struct {
    // Reserved and Preserved
    resvpresv: u6, // R/W

    // Event Ring Segement Table Base Address
    // Actual address = event_ring_segment_table_base_address << 6
    event_ring_segment_table_base_address: u58,
};

const EventRingDequeuePointer = packed struct {
    // Dequeue ERST Segment Index
    dequeue_erst_segment_index: u3, // R/W

    // Event Handler Busy
    event_handler_busy: bool, // R/WC

    // Event Ring Dequeue Pointer
    // Actual address = event_ring_segment_table_base_address << 4
    event_ring_dequeue_pointer: u60, // R/W
};

const DoorbellRegisterSet = packed struct {
    // Command Doorbell Register
    command_doorbell: CommandDoorbell,

    // Device Slot Doorbells
    // Size is actually MaxSlots - 1, so this will overlap with another struct. BE CAREFUL
    device_slot_doorbells: [255]DeviceSlotDoorbell,
};

const CommandDoorbell = packed struct {
    // Target
    target: DoorbellTarget, // R/W

    // Reserved and Zero'd
    resvzrd: u24, // R/W
};

const DeviceSlotDoorbell = packed struct {
    // Target
    target: DoorbellTarget, // R/W

    // Reserved and Zero'd
    resvzrd: u8, // R/W

    // Doorbell Stream ID
    doorbell_stream_id: u16, // R/W
};

const DoorbellTarget = enum(u8) {
    reserved_for_command_doorbell = 0,
    control_endpoint_enqueue_pointer_update = 1,
    endpoint1_out_enqueue_pointer_update = 2,
    endpoint1_in_enqueue_pointer_update = 3,
    endpoint2_out_enqueue_pointer_update = 4,
    endpoint2_in_enqueue_pointer_update = 5,
    endpoint3_out_enqueue_pointer_update = 6,
    endpoint3_in_enqueue_pointer_update = 7,
    endpoint4_out_enqueue_pointer_update = 8,
    endpoint4_in_enqueue_pointer_update = 9,
    endpoint5_out_enqueue_pointer_update = 10,
    endpoint5_in_enqueue_pointer_update = 11,
    endpoint6_out_enqueue_pointer_update = 12,
    endpoint6_in_enqueue_pointer_update = 13,
    endpoint7_out_enqueue_pointer_update = 14,
    endpoint7_in_enqueue_pointer_update = 15,
    endpoint8_out_enqueue_pointer_update = 16,
    endpoint8_in_enqueue_pointer_update = 17,
    endpoint9_out_enqueue_pointer_update = 18,
    endpoint9_in_enqueue_pointer_update = 19,
    endpoint10_out_enqueue_pointer_update = 20,
    endpoint10_in_enqueue_pointer_update = 21,
    endpoint11_out_enqueue_pointer_update = 22,
    endpoint11_in_enqueue_pointer_update = 23,
    endpoint12_out_enqueue_pointer_update = 24,
    endpoint12_in_enqueue_pointer_update = 25,
    endpoint13_out_enqueue_pointer_update = 26,
    endpoint13_in_enqueue_pointer_update = 27,
    endpoint14_out_enqueue_pointer_update = 28,
    endpoint14_in_enqueue_pointer_update = 29,
    endpoint15_out_enqueue_pointer_update = 30,
    endpoint15_in_enqueue_pointer_update = 31,
    resv0 = 32,
    resv1 = 33,
    resv2 = 34,
    resv3 = 35,
    resv4 = 36,
    resv5 = 37,
    resv6 = 38,
    resv7 = 39,
    resv8 = 40,
    resv9 = 41,
    resv10 = 42,
    resv11 = 43,
    resv12 = 44,
    resv13 = 45,
    resv14 = 46,
    resv15 = 47,
    resv16 = 48,
    resv17 = 49,
    resv18 = 50,
    resv19 = 51,
    resv20 = 52,
    resv21 = 53,
    resv22 = 54,
    resv23 = 55,
    resv24 = 56,
    resv25 = 57,
    resv26 = 58,
    resv27 = 59,
    resv28 = 60,
    resv29 = 61,
    resv30 = 62,
    resv31 = 63,
    resv32 = 64,
    resv33 = 65,
    resv34 = 66,
    resv35 = 67,
    resv36 = 68,
    resv37 = 69,
    resv38 = 70,
    resv39 = 71,
    resv40 = 72,
    resv41 = 73,
    resv42 = 74,
    resv43 = 75,
    resv44 = 76,
    resv45 = 77,
    resv46 = 78,
    resv47 = 79,
    resv48 = 80,
    resv49 = 81,
    resv50 = 82,
    resv51 = 83,
    resv52 = 84,
    resv53 = 85,
    resv54 = 86,
    resv55 = 87,
    resv56 = 88,
    resv57 = 89,
    resv58 = 90,
    resv59 = 91,
    resv60 = 92,
    resv61 = 93,
    resv62 = 94,
    resv63 = 95,
    resv64 = 96,
    resv65 = 97,
    resv66 = 98,
    resv67 = 99,
    resv68 = 100,
    resv69 = 101,
    resv70 = 102,
    resv71 = 103,
    resv72 = 104,
    resv73 = 105,
    resv74 = 106,
    resv75 = 107,
    resv76 = 108,
    resv77 = 109,
    resv78 = 110,
    resv79 = 111,
    resv80 = 112,
    resv81 = 113,
    resv82 = 114,
    resv83 = 115,
    resv84 = 116,
    resv85 = 117,
    resv86 = 118,
    resv87 = 119,
    resv88 = 120,
    resv89 = 121,
    resv90 = 122,
    resv91 = 123,
    resv92 = 124,
    resv93 = 125,
    resv94 = 126,
    resv95 = 127,
    resv96 = 128,
    resv97 = 129,
    resv98 = 130,
    resv99 = 131,
    resv100 = 132,
    resv101 = 133,
    resv102 = 134,
    resv103 = 135,
    resv104 = 136,
    resv105 = 137,
    resv106 = 138,
    resv107 = 139,
    resv108 = 140,
    resv109 = 141,
    resv110 = 142,
    resv111 = 143,
    resv112 = 144,
    resv113 = 145,
    resv114 = 146,
    resv115 = 147,
    resv116 = 148,
    resv117 = 149,
    resv118 = 150,
    resv119 = 151,
    resv120 = 152,
    resv121 = 153,
    resv122 = 154,
    resv123 = 155,
    resv124 = 156,
    resv125 = 157,
    resv126 = 158,
    resv127 = 159,
    resv128 = 160,
    resv129 = 161,
    resv130 = 162,
    resv131 = 163,
    resv132 = 164,
    resv133 = 165,
    resv134 = 166,
    resv135 = 167,
    resv136 = 168,
    resv137 = 169,
    resv138 = 170,
    resv139 = 171,
    resv140 = 172,
    resv141 = 173,
    resv142 = 174,
    resv143 = 175,
    resv144 = 176,
    resv145 = 177,
    resv146 = 178,
    resv147 = 179,
    resv148 = 180,
    resv149 = 181,
    resv150 = 182,
    resv151 = 183,
    resv152 = 184,
    resv153 = 185,
    resv154 = 186,
    resv155 = 187,
    resv156 = 188,
    resv157 = 189,
    resv158 = 190,
    resv159 = 191,
    resv160 = 192,
    resv161 = 193,
    resv162 = 194,
    resv163 = 195,
    resv164 = 196,
    resv165 = 197,
    resv166 = 198,
    resv167 = 199,
    resv168 = 200,
    resv169 = 201,
    resv170 = 202,
    resv171 = 203,
    resv172 = 204,
    resv173 = 205,
    resv174 = 206,
    resv175 = 207,
    resv176 = 208,
    resv177 = 209,
    resv178 = 210,
    resv179 = 211,
    resv180 = 212,
    resv181 = 213,
    resv182 = 214,
    resv183 = 215,
    resv184 = 216,
    resv185 = 217,
    resv186 = 218,
    resv187 = 219,
    resv188 = 220,
    resv189 = 221,
    resv190 = 222,
    resv191 = 223,
    resv192 = 224,
    resv193 = 225,
    resv194 = 226,
    resv195 = 227,
    resv196 = 228,
    resv197 = 229,
    resv198 = 230,
    resv199 = 231,
    resv200 = 232,
    resv201 = 233,
    resv202 = 234,
    resv203 = 235,
    resv204 = 236,
    resv205 = 237,
    resv206 = 238,
    resv207 = 239,
    resv208 = 240,
    resv209 = 241,
    resv210 = 242,
    resv211 = 243,
    resv212 = 244,
    resv213 = 245,
    resv214 = 246,
    resv215 = 247,
    vendor0 = 248,
    vendor1 = 249,
    vendor2 = 250,
    vendor3 = 251,
    vendor4 = 252,
    vendor5 = 253,
    vendor6 = 254,
    vendor7 = 255,
};
