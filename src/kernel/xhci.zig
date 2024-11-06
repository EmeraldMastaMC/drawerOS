// https://www.intel.com/content/dam/www/public/us/en/documents/technical-specifications/extensible-host-controler-interface-usb-xhci.pdf
const pci = @import("pci.zig");
const page_allocator = @import("page_frame_allocator.zig");
const paging = @import("paging.zig");

const CapabilityRegisters = packed struct {
    len: u8,
    reserved: u8,
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
    reserved: u5,
    max_ports: u8,
};
const OperationalRegisters = packed struct {
    usb_cmd: u32,
    usb_status: u32,
    page_size: u32,
    reserved0: u64,
    device_notification_control: u32,
    command_ring_control: u64,
    reserved1: u128,
    device_context_base_address_array_pointer: u64,
    configure: u32,
    reserved2: [964]u8 = [_]u8{0} ** 964,
    port_register_sets: [256]PortRegisterSet,
};

const PortRegisterSet = packed struct {
    port_status_and_control: u32,
    port_power_management_status_and_control: u32,
    port_link_info: u32,
    port_hardware_lpm_control: u32,
};

const RuntimeRegisters = packed struct {
    microframe_index: u32,
    reserved: u224,
    interrupter_register_sets: [1024]InterrupterRegisterSet,
};

const InterrupterRegisterSet = packed struct {
    interrupter_management: u32,
    interrupter_moderation: u32,
    event_ring_segment_table_size: u32,
    reserved: u32,
    event_ring_segment_table_base_address: u64,
    event_ring_dequeue_pointer: u64,
};

const DoorbellRegisters = packed struct {
    doorbell_target: u8,
    reserved: u8,
    doorbell_task_id: u16,
};

const SlotContext = packed struct {
    route_string: u20,
    speed: u4,
    reserved0: u1 = 0,
    mtt: u1,
    hub: u1,
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
    lsa: u1,
    interval: u8,
    max_esit_payload_hi: u8,
    reserved1: u1,
    cerr: u2,
    ep_type: u3,
    reserved2: u1 = 0,
    hid: u1,
    max_burst_size: u8,
    max_packet_size: u16,
    ocs: u1,
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
