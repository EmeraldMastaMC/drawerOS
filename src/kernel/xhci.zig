// https://www.intel.com/content/dam/www/public/us/en/documents/technical-specifications/extensible-host-controler-interface-usb-xhci.pdf
const pci = @import("pci.zig");
const page_allocator = @import("page_frame_allocator.zig");
const paging = @import("paging.zig");

const CapabilityRegisters = packed struct {
    len: u8,
    reserved: u8 = 0,
    hci_version: u16,
    hcs_params1: HcsParams1,
    hcs_params2: u32,
    hcs_params3: u32,
    hcc_params1: u32,
    doorbell_offset: u32,
    runtime_registers_space_offset: u32,
    hcc_params2: u32,
};

const HcsParams1 = packed struct {
    max_device_slots: u8,
    max_interrupters: u11,
    reserved: u5 = 0,
    max_ports: u8,
};

const HccParams1 = packed struct {
    addressing_64_capability: bool,
    bandwidth_negotiation_capability: bool,
    context_size: bool,
    port_power_control: bool,
    port_indicators: bool,
    light_host_controller_reset_capability: bool,
    latency_tolerance_messaging_capability: bool,
    no_secondary_streaming_id_support: bool,
    parse_all_event_data: bool,
    stopped_short_packet_capability: bool,
    stopped_edtla_capability: bool,
    continuous_frame_id_capability: bool,
    maximum_primary_stream_array_size: u4,
    xhci_extended_capabilities_pointer: u16,
};

const HccParams2 = packed struct {
    u3_entry_capability: bool,
    configep_command_max_exit_latency_too_large: bool,
    force_save_context_capability: bool,
    compliance_transition_capability: bool,
    large_esit_payload_capability: bool,
    configuration_information_capability: bool,
    reserved: u26 = 0,
};
const OperationalRegisters = packed struct {
    usb_cmd: u32,
    usb_status: u32,
    page_size: u32, // first 16 bits for page size, rest reserved, (page_size & 0xFFFF) << 12
    reserved0: u64 = 0,
    device_notification_control: u32, // first 16 bits for flags, rest reserved
    command_ring_control: u64,
    reserved1: u128 = 0,
    device_context_base_address_array_pointer: u64,
    configure: u32,
    reserved2: [964]u8 = [_]u8{0} ** 964,
    port_register_sets: [256]PortRegisterSet,
};

const UsbCommand = enum(u32) {
    run_stop = 0x00000001, // RW
    host_controller_reset = 0x00000002, // RW
    interrupt_enable = 0x00000004, // RW
    host_system_error_enable = 0x00000008, // RW
    light_host_controller_reset = 0x00000080, // RW / RO
    controller_save_state = 0x00000100, // RW
    controller_restore_state = 0x00000200, // RW
    enable_wrap_event = 0x00000400, // RW
    enable_u3_mfindex_stop = 0x00000800, // RW
    stopped_short_packet_enable = 0x00001000, // RW
    cem_enable = 0x00002000, // RW
};

const UsbStatus = enum(u32) {
    host_controller_halted = 0x00000001, // RO
    host_system_error = 0x00000004, // RWC
    event_interrupt = 0x00000008, // RWC
    port_change_detected = 0x00000010, // RWC
    save_state_status = 0x00000100, // RO
    restore_state_status = 0x00000200, // RO
    save_restore_error = 0x00000400, // RWC
    controller_not_ready = 0x00000800, // RO
    host_controller_error = 0x00001000, // RO
};

const DeviceNotificationControl = enum(u32) {
    notification_enable0 = 0x00000001, // RW
    notification_enable1 = 0x00000002, // RW
    notification_enable2 = 0x00000004, // RW
    notification_enable3 = 0x00000008, // RW
    notification_enable4 = 0x00000010, // RW
    notification_enable5 = 0x00000020, // RW
    notification_enable6 = 0x00000040, // RW
    notification_enable7 = 0x00000080, // RW
    notification_enable8 = 0x00000100, // RW
    notification_enable9 = 0x00000200, // RW
    notification_enable10 = 0x00000400, // RW
    notification_enable11 = 0x00000800, // RW
    notification_enable12 = 0x00001000, // RW
    notification_enable13 = 0x00002000, // RW
    notification_enable14 = 0x00004000, // RW
    notification_enable15 = 0x00008000, // RW
};

const CommandRingControl = enum(u64) {
    ring_cycle_state = 0x0000000000000001, // RW
    command_stop = 0x0000000000000002, // RWC
    command_abort = 0x0000000000000004, // RWC
    command_ring_running = 0x0000000000000008, // RO
    command_ring_pointer = 0xFFFFFFFFFFFFFFC0, // RW
};

const PortRegisterSet = packed struct {
    port_status_and_control: u32,
    port_power_management_status_and_control: u32,
    port_link_info: u32,
    port_hardware_lpm_control: u32,
};

const RuntimeRegisters = packed struct {
    microframe_index: u32,
    reserved: u224 = 0,
    interrupter_register_sets: [1024]InterrupterRegisterSet,
};

const InterrupterRegisterSet = packed struct {
    interrupter_management: u32,
    interrupter_moderation: u32,
    event_ring_segment_table_size: u32,
    reserved: u32 = 0,
    event_ring_segment_table_base_address: u64,
    event_ring_dequeue_pointer: u64,
};

const DoorbellRegisters = packed struct {
    doorbell_target: u8,
    reserved: u8 = 0,
    doorbell_task_id: u16,
};

const SlotContext = packed struct {
    route_string: u20,
    speed: u4,
    reserved0: u1 = 0,
    mtt: bool,
    hub: bool,
    context_entries: u5,
    max_exit_latency: u16,
    root_hub_port_number: u8,
    num_of_ports: u8,
    tt_hub_slot_id: u8,
    tt_port_num: u8,
    ttt: u2,
    reserved1: u4 = 0,
    interrupter_target: u10,
    usb_device_address: u8,
    reserved2: u19 = 0,
    slot_state: u5,
    reserved3: [2]u64 = [_]u64{0} ** 2,
};

const EndpointContext = packed struct {
    ep_state: u3,
    reserved0: u5 = 0,
    mult: u2,
    max_p_streams: u5,
    lsa: bool,
    interval: u8,
    max_esit_payload_hi: u8,
    reserved1: bool,
    cerr: u2,
    ep_type: u3,
    reserved2: u1 = 0,
    hid: bool,
    max_burst_size: u8,
    max_packet_size: u16,
    ocs: bool,
    reserved3: u3 = 0,
    tr_dequeue_pointer_lo: u28,
    tr_dequeue_pointer_hi: u32,
    average_trb_len: u16,
    max_esit_payload_lo: u16,
    reserved4: [3]u32 = [_]u32{0} ** 3,
};

const DeviceContext = packed struct {
    slot_context: SlotContext,
    endpoint_contexts: [33]EndpointContext,
};
pub const HostController = struct {
    device: pci.Device,
    capability_registers: *CapabilityRegisters,
    operational_registers: *OperationalRegisters,
    port_register_sets: [*]PortRegisterSet,
    interrupter_register_sets: [*]InterrupterRegisterSet,
    runtime_registers: *RuntimeRegisters,
    doorbell_registers: [*]DoorbellRegisters,

    // TODO: Write a function do initialize the XHCI host controller
};
