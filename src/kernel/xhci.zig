const pci = @import("pci.zig");

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
pub const Controller = struct {
    device: pci.Device,
    capability_registers: *CapabilityRegisters,
    operational_registers: *OperationalRegisters,
    port_register_sets: [*]PortRegisterSet,
    interrupter_register_sets: [*]InterrupterRegisterSet,
    runtime_registers: *RuntimeRegisters,
    doorbell_registers: [*]DoorbellRegisters,
    max_device_slots: u8,
    max_interrupters: u11,
    max_ports: u8,
};
