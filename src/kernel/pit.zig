const ports = @import("ports.zig");
const cpu = @import("cpu.zig");
const CHANNEL_0_DATA_PORT: u16 = 0x40; // R/W
const CHANNEL_1_DATA_PORT: u16 = 0x41; // R/W
const CHANNEL_2_DATA_PORT: u16 = 0x42; // R/W
const MODE_COMMAND_PORT: u16 = 0x43; // WO
const GATE_INPUT_PIN_PORT: u16 = 0x61; // R/W
const FREQUENCY: u32 = 1193183; // MHz

const CHANNEL_0 = 0x00;
const CHANNEL_1 = 0x40;
const CHANNEL_2 = 0x80;
const READ_BACK_COMMAND = 0xC0;

const LATCH_COUNT_VALUE: u8 = 0x00;
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
    One,
    Two,
    Three,
};

pub fn configure(channel: Channel, mode: Mode, target_freq: usize) void {
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
        Channel.One => CHANNEL_0,
        Channel.Two => CHANNEL_1,
        Channel.Three => CHANNEL_2,
    };

    const divisor: u16 = @truncate(FREQUENCY / target_freq);

    ports.outb(MODE_COMMAND_PORT, channel_flag | mode_flag | LOHI_BYTE_ACCESS_MODE);
    ports.outb(CHANNEL_2_DATA_PORT, @truncate(divisor & 0xFF));

    // Small Delay
    _ = ports.inb(0x60);

    ports.outb(CHANNEL_2_DATA_PORT, @truncate((divisor >> 8) & 0xFF));
}

pub fn reset() void {
    const tmp = ports.inb(GATE_INPUT_PIN_PORT);
    ports.outb(GATE_INPUT_PIN_PORT, tmp & 0xFE);
    ports.outb(GATE_INPUT_PIN_PORT, tmp | 0x01);
}

pub fn wait() void {
    // if bit 5 is not set, wait
    while ((ports.inb(GATE_INPUT_PIN_PORT) & 0x20) == 0) {
        cpu.nop();
    }
}

pub fn delay(cycles: usize) void {
    for (0..cycles) |_| {
        reset();
        wait();
    }
}
