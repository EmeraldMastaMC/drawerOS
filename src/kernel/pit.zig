const ports = @import("ports.zig");
const cpu = @import("cpu.zig");
const console = @import("console.zig");
const allocator = @import("page_frame_allocator.zig");
const CHANNEL_0_DATA_PORT: u16 = 0x40; // R/W
const CHANNEL_1_DATA_PORT: u16 = 0x41; // R/W
const CHANNEL_2_DATA_PORT: u16 = 0x42; // R/W
const MODE_COMMAND_PORT: u16 = 0x43; // WO
const GATE_INPUT_PIN_PORT: u16 = 0x61; // R/W
const FREQUENCY: u32 = 1193183; // Hz

const CHANNEL_0 = 0x00;
const CHANNEL_1 = 0x40;
const CHANNEL_2 = 0x80;
const READ_BACK_COMMAND = 0xC0;

const LATCH_COUNT_VALUE: u8 = 0x00;
const DONT_LATCH_COUNT_VALUE: u8 = 0x20;

const LO_BYTE_ACCESS_MODE: u8 = 0x10;
const HI_BYTE_ACCESS_MODE: u8 = 0x20;
const LOHI_BYTE_ACCESS_MODE: u8 = 0x30;

const MODE_INTERRUPT_ON_TERMINAL_COUNT: u8 = 0x00;
const MODE_ONE_SHOT: u8 = 0x02;
const MODE_RATE_GENERATOR: u8 = 0x04;
const MODE_SQUARE_WAVE_GENERATOR: u8 = 0x06;
const MODE_SOFTWARE_TRIGGER_STROBE: u8 = 0x08;
const MODE_HARDWARE_TRIGGER_STROBE: u8 = 0x0A;

pub const Mode = enum {
    InterruptOnTerminalCount,
    OneShot,
    RateGenerator,
    SquareWaveGenerator,
    SoftwareTriggerStrobe,
    HardwareTriggerStrobe,
};

pub const Channel = enum {
    Zero,
    One,
    Two,
};

pub fn configure(channel: Channel, mode: Mode) void {
    var mode_flag: u8 = undefined;
    mode_flag = switch (mode) {
        Mode.InterruptOnTerminalCount => MODE_INTERRUPT_ON_TERMINAL_COUNT,
        Mode.OneShot => MODE_ONE_SHOT,
        Mode.RateGenerator => MODE_RATE_GENERATOR,
        Mode.SquareWaveGenerator => MODE_SQUARE_WAVE_GENERATOR,
        Mode.SoftwareTriggerStrobe => MODE_SOFTWARE_TRIGGER_STROBE,
        Mode.HardwareTriggerStrobe => MODE_HARDWARE_TRIGGER_STROBE,
    };

    var channel_flag: u8 = undefined;
    channel_flag = switch (channel) {
        Channel.Zero => CHANNEL_0,
        Channel.One => CHANNEL_1,
        Channel.Two => CHANNEL_2,
    };

    if (channel_flag == CHANNEL_2) {
        ports.outb(GATE_INPUT_PIN_PORT, (ports.inb(GATE_INPUT_PIN_PORT) & 0xFD) | 1);
    }

    ports.outb(MODE_COMMAND_PORT, channel_flag | mode_flag | LOHI_BYTE_ACCESS_MODE);
}

fn reloadChannel2(target_freq: usize) void {
    const divisor: u16 = @truncate(FREQUENCY / target_freq);
    ports.outb(CHANNEL_2_DATA_PORT, @truncate(divisor & 0xFF));
    ports.outb(CHANNEL_2_DATA_PORT, @truncate(((divisor & 0xFF00) >> 8)));
}

pub inline fn resetChannel2() void {
    const tmp = ports.inb(GATE_INPUT_PIN_PORT);
    ports.outb(GATE_INPUT_PIN_PORT, tmp & 0xFE);
    ports.outb(GATE_INPUT_PIN_PORT, tmp | 1);
}

pub inline fn poll() u8 {
    return (ports.inb(GATE_INPUT_PIN_PORT) & 0x20) >> 5;
}

pub fn setFrequency(frequency: usize) void {
    reloadChannel2(frequency);
}
pub fn delay(cycles: usize) void {
    var counter: usize = 0;
    while (counter != cycles) {
        if (poll() == 1) {
            counter += 1;
            resetChannel2();
        }
    }
}
