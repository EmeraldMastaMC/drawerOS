const idt = @import("idt.zig");
const apic = @import("apic.zig");
const pit = @import("pit.zig");
const irq = @import("irq.zig");
const cpu = @import("cpu.zig");
const paging = @import("paging.zig");
const console = @import("console.zig");
const allocator = @import("page_frame_allocator.zig");
const heap_allocator = @import("heap_allocator.zig");
const stack = @import("stack.zig");
const pci = @import("pci.zig");
const colors = console.Color;

pub const PML4: [*]volatile paging.PML4Entry = @ptrFromInt(0x1000);
pub const PDP: [*]volatile paging.PDPEntry = @ptrFromInt(0x2000);
pub const PD: [*]volatile paging.PDEntry = @ptrFromInt(0x3000);
pub const PT: [*]volatile paging.PTEntry = @ptrFromInt(0xc0000);

pub const PML4_ENTRIES: u64 = 1;
pub const PDP_ENTRIES: u64 = 1;
pub const PD_ENTRIES: u64 = 300;
pub const PT_ENTRIES: u64 = 512;

export fn main() noreturn {
    // Use a writer that doesn't depend on interrupts to function.
    var raw_writer = console.RawWriter.new(colors.White, colors.Black);
    raw_writer.clear();

    raw_writer.putString("Identity Mapping 600MiB...\n");
    paging.identityMap(PML4, PML4_ENTRIES, PDP, PDP_ENTRIES, PD, PD_ENTRIES, PT, PT_ENTRIES);
    raw_writer.putString("Done.\n");

    raw_writer.putString("Initializing Page Frame Allocator...\n");
    allocator.init();
    raw_writer.putString("Done.\n");

    raw_writer.putString("Allocating Stack 40KiB...\n");
    stack.init(allocator.alloc(10));
    raw_writer.putString("Done.\n");

    // Load IRQ 32 with a function, and then load the IDT.
    raw_writer.putString("Loading Interrupt Descriptor Table...\n");
    idt.initEntries();
    idt.load();
    raw_writer.putString("Done.\n");

    raw_writer.putString("Initializing Programmable Interval Timer\n");
    pit.configure(pit.Channel.Two, pit.Mode.OneShot);
    raw_writer.putString("Done.\n");
    // apic.enable();
    // allocator.reserve(apic.getAPICBase(), 1);

    // Use a writer that depends on interrupts to function.
    pit.setFrequency(1000);
    pit.delay(1000);
    const back_buffer: [*]volatile u16 = @ptrFromInt(allocator.alloc(10));
    defer allocator.free(@intFromPtr(back_buffer), 10);
    var writer = console.Writer.new(colors.White, colors.Black, back_buffer);
    writer.enableCursor();
    writer.putLn();
    writer.setColors(colors.LightGreen, colors.Black);
    writer.putString("Welcome to DrawerOS!\n");
    writer.setColors(colors.White, colors.Black);

    // {
    //     const num_pci_devices = pci.numDevices();
    //
    //     writer.putString("Detected ");
    //     writer.putHexWord(@truncate(num_pci_devices));
    //     writer.putString(" PCI devices.\n");
    //
    //     var heap = heap_allocator.Heap.new((num_pci_devices * @sizeOf(pci.Device)) / paging.PAGE_SIZE + 1);
    //     defer heap.deinit();
    //     var pci_devices: [*]pci.Device = @ptrCast(@alignCast(heap.alloc(@sizeOf(pci.Device) * num_pci_devices, 16)));
    //
    //     var i: usize = 0;
    //
    //     // Populate device array with devices
    //     for (0..256) |bus| {
    //         for (0..256) |slot| {
    //             if (pci.deviceExists(@truncate(bus), @truncate(slot))) {
    //                 pci_devices[i] = pci.Device.new(@truncate(bus), @truncate(slot));
    //                 i += 1;
    //             }
    //         }
    //     }
    //
    //     for (0..num_pci_devices) |j| {
    //         writer.putHexWord(pci_devices[j].vendor_id);
    //         writer.putLn();
    //         writer.putHexQuad(pci_devices[j].bar_size);
    //         writer.putLn();
    //     }
    //
    //     // Display back buffer to screen
    //     writer.flush();
    // }

    pit.setFrequency(1000);
    for (1..10000) |i| {
        writer.putLn();
        writer.putNum(i);
        writer.flush();
        pit.delay(1000);
    }
    fullHLT();
}

fn fullHLT() noreturn {
    while (true) {
        cpu.cli();
        cpu.hlt();
    }
}
