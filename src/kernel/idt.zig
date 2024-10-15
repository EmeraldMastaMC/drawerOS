const INTERRUPT_GATE: u8 = 0b00001110;
const TRAP_GATE: u8 = 0b00001111;
const RING_0: u8 = 0b00000000;
const RING_1: u8 = 0b00100000;
const RING_2: u8 = 0b01000000;
const RING_3: u8 = 0b01100000;
const PRESENT: u8 = 0b10000000;

const IDT_MAX_DESCRIPTORS: usize = 256;

const InterruptDescriptor64 = packed struct {
    offset_1: u16,
    selector: u16,
    interrupt_stack_table: u8 = 0,
    type_attributes: u8,
    offset_2: u16,
    offset_3: u32,
    reserved: u32 = 0,
};

const IDTR = packed struct(u80) {
    limit: u16,
    base: u64,
};

pub var InterruptDescriptorTable: [IDT_MAX_DESCRIPTORS]InterruptDescriptor64 = undefined;

pub fn entry(index: u8, isr: usize) void {
    const descriptor = &InterruptDescriptorTable[index];
    descriptor.offset_1 = @truncate(isr & 0xFFFF);
    descriptor.selector = 0x08;
    descriptor.type_attributes = INTERRUPT_GATE | RING_0 | PRESENT;
    descriptor.offset_2 = @truncate((isr >> 16) & 0xFFFF);
    descriptor.offset_3 = @truncate(isr >> 32);
}

pub fn load() void {
    const idtr = IDTR{
        .limit = @as(u16, @sizeOf(InterruptDescriptor64)) * IDT_MAX_DESCRIPTORS - 1,
        .base = @as(usize, @intFromPtr(@as(*void, @ptrCast(&InterruptDescriptorTable[0])))),
    };

    lidt(@bitCast(idtr));

    return;
}

fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}
