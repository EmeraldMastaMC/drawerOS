const cpu = @import("cpu.zig");
const irq = @import("irq.zig");
const ports = @import("ports.zig");
const paging = @import("paging.zig");

// See section 4.6.5 of the manual for information regarding the Interrupt Descriptor Table
//
const INTERRUPT_GATE: u8 = 0b00001110;
const TRAP_GATE: u8 = 0b00001111;
const RING_0: u8 = 0b00000000;
const RING_1: u8 = 0b00100000;
const RING_2: u8 = 0b01000000;
const RING_3: u8 = 0b01100000;
const PRESENT: u8 = 0b10000000;

const IDT_MAX_DESCRIPTORS: usize = 256;

// See section 4.8.4 of the manual for information regarding Gate Descriptors
const InterruptDescriptor64 = packed struct {
    offset_1: u16,
    selector: u16,
    interrupt_stack_table: u8 = 0,
    type_attributes: u8,
    offset_2: u16,
    offset_3: u32,
    reserved: u32 = 0,
};

// See figure 4-8 of the manual for information regarding the IDTR
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

    cpu.lidt(@bitCast(idtr));

    // disable 8259PIC
    ports.outb(0x21, 0xFF);
    ports.outb(0xA1, 0xFF);

    cpu.sti();

    return;
}

pub inline fn initEntries() void {
    entry(0, @as(usize, @intFromPtr(&irq.irq255)));
    entry(1, @as(usize, @intFromPtr(&irq.irq255)));
    entry(2, @as(usize, @intFromPtr(&irq.irq255)));
    entry(3, @as(usize, @intFromPtr(&irq.irq255)));
    entry(4, @as(usize, @intFromPtr(&irq.irq255)));
    entry(5, @as(usize, @intFromPtr(&irq.irq255)));
    entry(6, @as(usize, @intFromPtr(&irq.irq255)));
    entry(7, @as(usize, @intFromPtr(&irq.irq255)));
    entry(8, @as(usize, @intFromPtr(&irq.irq255)));
    entry(9, @as(usize, @intFromPtr(&irq.irq255)));
    entry(10, @as(usize, @intFromPtr(&irq.irq255)));
    entry(11, @as(usize, @intFromPtr(&irq.irq255)));
    entry(12, @as(usize, @intFromPtr(&irq.irq255)));
    entry(13, @as(usize, @intFromPtr(&irq.irq255)));
    entry(14, @as(usize, @intFromPtr(&irq.irq255)));
    entry(15, @as(usize, @intFromPtr(&irq.irq255)));
    entry(16, @as(usize, @intFromPtr(&irq.irq255)));
    entry(17, @as(usize, @intFromPtr(&irq.irq255)));
    entry(18, @as(usize, @intFromPtr(&irq.irq255)));
    entry(19, @as(usize, @intFromPtr(&irq.irq255)));
    entry(20, @as(usize, @intFromPtr(&irq.irq255)));
    entry(21, @as(usize, @intFromPtr(&irq.irq255)));
    entry(22, @as(usize, @intFromPtr(&irq.irq255)));
    entry(23, @as(usize, @intFromPtr(&irq.irq255)));
    entry(24, @as(usize, @intFromPtr(&irq.irq255)));
    entry(25, @as(usize, @intFromPtr(&irq.irq255)));
    entry(26, @as(usize, @intFromPtr(&irq.irq255)));
    entry(27, @as(usize, @intFromPtr(&irq.irq255)));
    entry(28, @as(usize, @intFromPtr(&irq.irq255)));
    entry(29, @as(usize, @intFromPtr(&irq.irq255)));
    entry(30, @as(usize, @intFromPtr(&irq.irq255)));
    entry(31, @as(usize, @intFromPtr(&irq.irq255)));
    entry(32, @as(usize, @intFromPtr(&irq.irq0)));
    entry(33, @as(usize, @intFromPtr(&irq.irq1)));
    entry(34, @as(usize, @intFromPtr(&irq.irq255)));
    entry(35, @as(usize, @intFromPtr(&irq.irq255)));
    entry(36, @as(usize, @intFromPtr(&irq.irq255)));
    entry(37, @as(usize, @intFromPtr(&irq.irq255)));
    entry(38, @as(usize, @intFromPtr(&irq.irq255)));
    entry(39, @as(usize, @intFromPtr(&irq.irq255)));
    entry(40, @as(usize, @intFromPtr(&irq.irq255)));
    entry(41, @as(usize, @intFromPtr(&irq.irq255)));
    entry(42, @as(usize, @intFromPtr(&irq.irq255)));
    entry(43, @as(usize, @intFromPtr(&irq.irq255)));
    entry(44, @as(usize, @intFromPtr(&irq.irq255)));
    entry(45, @as(usize, @intFromPtr(&irq.irq255)));
    entry(46, @as(usize, @intFromPtr(&irq.irq255)));
    entry(47, @as(usize, @intFromPtr(&irq.irq255)));
    entry(48, @as(usize, @intFromPtr(&irq.irq255)));
    entry(49, @as(usize, @intFromPtr(&irq.irq255)));
    entry(50, @as(usize, @intFromPtr(&irq.irq255)));
    entry(51, @as(usize, @intFromPtr(&irq.irq255)));
    entry(52, @as(usize, @intFromPtr(&irq.irq255)));
    entry(53, @as(usize, @intFromPtr(&irq.irq255)));
    entry(54, @as(usize, @intFromPtr(&irq.irq255)));
    entry(55, @as(usize, @intFromPtr(&irq.irq255)));
    entry(56, @as(usize, @intFromPtr(&irq.irq255)));
    entry(57, @as(usize, @intFromPtr(&irq.irq255)));
    entry(58, @as(usize, @intFromPtr(&irq.irq255)));
    entry(59, @as(usize, @intFromPtr(&irq.irq255)));
    entry(60, @as(usize, @intFromPtr(&irq.irq255)));
    entry(61, @as(usize, @intFromPtr(&irq.irq255)));
    entry(62, @as(usize, @intFromPtr(&irq.irq255)));
    entry(63, @as(usize, @intFromPtr(&irq.irq255)));
    entry(64, @as(usize, @intFromPtr(&irq.irq255)));
    entry(65, @as(usize, @intFromPtr(&irq.irq255)));
    entry(66, @as(usize, @intFromPtr(&irq.irq255)));
    entry(67, @as(usize, @intFromPtr(&irq.irq255)));
    entry(68, @as(usize, @intFromPtr(&irq.irq255)));
    entry(69, @as(usize, @intFromPtr(&irq.irq255)));
    entry(70, @as(usize, @intFromPtr(&irq.irq255)));
    entry(71, @as(usize, @intFromPtr(&irq.irq255)));
    entry(72, @as(usize, @intFromPtr(&irq.irq255)));
    entry(73, @as(usize, @intFromPtr(&irq.irq255)));
    entry(74, @as(usize, @intFromPtr(&irq.irq255)));
    entry(75, @as(usize, @intFromPtr(&irq.irq255)));
    entry(76, @as(usize, @intFromPtr(&irq.irq255)));
    entry(77, @as(usize, @intFromPtr(&irq.irq255)));
    entry(78, @as(usize, @intFromPtr(&irq.irq255)));
    entry(79, @as(usize, @intFromPtr(&irq.irq255)));
    entry(80, @as(usize, @intFromPtr(&irq.irq255)));
    entry(81, @as(usize, @intFromPtr(&irq.irq255)));
    entry(82, @as(usize, @intFromPtr(&irq.irq255)));
    entry(83, @as(usize, @intFromPtr(&irq.irq255)));
    entry(84, @as(usize, @intFromPtr(&irq.irq255)));
    entry(85, @as(usize, @intFromPtr(&irq.irq255)));
    entry(86, @as(usize, @intFromPtr(&irq.irq255)));
    entry(87, @as(usize, @intFromPtr(&irq.irq255)));
    entry(88, @as(usize, @intFromPtr(&irq.irq255)));
    entry(89, @as(usize, @intFromPtr(&irq.irq255)));
    entry(90, @as(usize, @intFromPtr(&irq.irq255)));
    entry(91, @as(usize, @intFromPtr(&irq.irq255)));
    entry(92, @as(usize, @intFromPtr(&irq.irq255)));
    entry(93, @as(usize, @intFromPtr(&irq.irq255)));
    entry(94, @as(usize, @intFromPtr(&irq.irq255)));
    entry(95, @as(usize, @intFromPtr(&irq.irq255)));
    entry(96, @as(usize, @intFromPtr(&irq.irq255)));
    entry(97, @as(usize, @intFromPtr(&irq.irq255)));
    entry(98, @as(usize, @intFromPtr(&irq.irq255)));
    entry(99, @as(usize, @intFromPtr(&irq.irq255)));
    entry(100, @as(usize, @intFromPtr(&irq.irq255)));
    entry(101, @as(usize, @intFromPtr(&irq.irq255)));
    entry(102, @as(usize, @intFromPtr(&irq.irq255)));
    entry(103, @as(usize, @intFromPtr(&irq.irq255)));
    entry(104, @as(usize, @intFromPtr(&irq.irq255)));
    entry(105, @as(usize, @intFromPtr(&irq.irq255)));
    entry(106, @as(usize, @intFromPtr(&irq.irq255)));
    entry(107, @as(usize, @intFromPtr(&irq.irq255)));
    entry(108, @as(usize, @intFromPtr(&irq.irq255)));
    entry(109, @as(usize, @intFromPtr(&irq.irq255)));
    entry(110, @as(usize, @intFromPtr(&irq.irq255)));
    entry(111, @as(usize, @intFromPtr(&irq.irq255)));
    entry(112, @as(usize, @intFromPtr(&irq.irq255)));
    entry(113, @as(usize, @intFromPtr(&irq.irq255)));
    entry(114, @as(usize, @intFromPtr(&irq.irq255)));
    entry(115, @as(usize, @intFromPtr(&irq.irq255)));
    entry(116, @as(usize, @intFromPtr(&irq.irq255)));
    entry(117, @as(usize, @intFromPtr(&irq.irq255)));
    entry(118, @as(usize, @intFromPtr(&irq.irq255)));
    entry(119, @as(usize, @intFromPtr(&irq.irq255)));
    entry(120, @as(usize, @intFromPtr(&irq.irq255)));
    entry(121, @as(usize, @intFromPtr(&irq.irq255)));
    entry(122, @as(usize, @intFromPtr(&irq.irq255)));
    entry(123, @as(usize, @intFromPtr(&irq.irq255)));
    entry(124, @as(usize, @intFromPtr(&irq.irq255)));
    entry(125, @as(usize, @intFromPtr(&irq.irq255)));
    entry(126, @as(usize, @intFromPtr(&irq.irq255)));
    entry(127, @as(usize, @intFromPtr(&irq.irq255)));
    entry(128, @as(usize, @intFromPtr(&irq.irq255)));
    entry(129, @as(usize, @intFromPtr(&irq.irq255)));
    entry(130, @as(usize, @intFromPtr(&irq.irq255)));
    entry(131, @as(usize, @intFromPtr(&irq.irq255)));
    entry(132, @as(usize, @intFromPtr(&irq.irq255)));
    entry(133, @as(usize, @intFromPtr(&irq.irq255)));
    entry(134, @as(usize, @intFromPtr(&irq.irq255)));
    entry(135, @as(usize, @intFromPtr(&irq.irq255)));
    entry(136, @as(usize, @intFromPtr(&irq.irq255)));
    entry(137, @as(usize, @intFromPtr(&irq.irq255)));
    entry(138, @as(usize, @intFromPtr(&irq.irq255)));
    entry(139, @as(usize, @intFromPtr(&irq.irq255)));
    entry(140, @as(usize, @intFromPtr(&irq.irq255)));
    entry(141, @as(usize, @intFromPtr(&irq.irq255)));
    entry(142, @as(usize, @intFromPtr(&irq.irq255)));
    entry(143, @as(usize, @intFromPtr(&irq.irq255)));
    entry(144, @as(usize, @intFromPtr(&irq.irq255)));
    entry(145, @as(usize, @intFromPtr(&irq.irq255)));
    entry(146, @as(usize, @intFromPtr(&irq.irq255)));
    entry(147, @as(usize, @intFromPtr(&irq.irq255)));
    entry(148, @as(usize, @intFromPtr(&irq.irq255)));
    entry(149, @as(usize, @intFromPtr(&irq.irq255)));
    entry(150, @as(usize, @intFromPtr(&irq.irq255)));
    entry(151, @as(usize, @intFromPtr(&irq.irq255)));
    entry(152, @as(usize, @intFromPtr(&irq.irq255)));
    entry(153, @as(usize, @intFromPtr(&irq.irq255)));
    entry(154, @as(usize, @intFromPtr(&irq.irq255)));
    entry(155, @as(usize, @intFromPtr(&irq.irq255)));
    entry(156, @as(usize, @intFromPtr(&irq.irq255)));
    entry(157, @as(usize, @intFromPtr(&irq.irq255)));
    entry(158, @as(usize, @intFromPtr(&irq.irq255)));
    entry(159, @as(usize, @intFromPtr(&irq.irq255)));
    entry(160, @as(usize, @intFromPtr(&irq.irq255)));
    entry(161, @as(usize, @intFromPtr(&irq.irq255)));
    entry(162, @as(usize, @intFromPtr(&irq.irq255)));
    entry(163, @as(usize, @intFromPtr(&irq.irq255)));
    entry(164, @as(usize, @intFromPtr(&irq.irq255)));
    entry(165, @as(usize, @intFromPtr(&irq.irq255)));
    entry(166, @as(usize, @intFromPtr(&irq.irq255)));
    entry(167, @as(usize, @intFromPtr(&irq.irq255)));
    entry(168, @as(usize, @intFromPtr(&irq.irq255)));
    entry(169, @as(usize, @intFromPtr(&irq.irq255)));
    entry(170, @as(usize, @intFromPtr(&irq.irq255)));
    entry(171, @as(usize, @intFromPtr(&irq.irq255)));
    entry(172, @as(usize, @intFromPtr(&irq.irq255)));
    entry(173, @as(usize, @intFromPtr(&irq.irq255)));
    entry(174, @as(usize, @intFromPtr(&irq.irq255)));
    entry(175, @as(usize, @intFromPtr(&irq.irq255)));
    entry(176, @as(usize, @intFromPtr(&irq.irq255)));
    entry(177, @as(usize, @intFromPtr(&irq.irq255)));
    entry(178, @as(usize, @intFromPtr(&irq.irq255)));
    entry(179, @as(usize, @intFromPtr(&irq.irq255)));
    entry(180, @as(usize, @intFromPtr(&irq.irq255)));
    entry(181, @as(usize, @intFromPtr(&irq.irq255)));
    entry(182, @as(usize, @intFromPtr(&irq.irq255)));
    entry(183, @as(usize, @intFromPtr(&irq.irq255)));
    entry(184, @as(usize, @intFromPtr(&irq.irq255)));
    entry(185, @as(usize, @intFromPtr(&irq.irq255)));
    entry(186, @as(usize, @intFromPtr(&irq.irq255)));
    entry(187, @as(usize, @intFromPtr(&irq.irq255)));
    entry(188, @as(usize, @intFromPtr(&irq.irq255)));
    entry(189, @as(usize, @intFromPtr(&irq.irq255)));
    entry(190, @as(usize, @intFromPtr(&irq.irq255)));
    entry(191, @as(usize, @intFromPtr(&irq.irq255)));
    entry(192, @as(usize, @intFromPtr(&irq.irq255)));
    entry(193, @as(usize, @intFromPtr(&irq.irq255)));
    entry(194, @as(usize, @intFromPtr(&irq.irq255)));
    entry(195, @as(usize, @intFromPtr(&irq.irq255)));
    entry(196, @as(usize, @intFromPtr(&irq.irq255)));
    entry(197, @as(usize, @intFromPtr(&irq.irq255)));
    entry(198, @as(usize, @intFromPtr(&irq.irq255)));
    entry(199, @as(usize, @intFromPtr(&irq.irq255)));
    entry(200, @as(usize, @intFromPtr(&irq.irq255)));
    entry(201, @as(usize, @intFromPtr(&irq.irq255)));
    entry(202, @as(usize, @intFromPtr(&irq.irq255)));
    entry(203, @as(usize, @intFromPtr(&irq.irq255)));
    entry(204, @as(usize, @intFromPtr(&irq.irq255)));
    entry(205, @as(usize, @intFromPtr(&irq.irq255)));
    entry(206, @as(usize, @intFromPtr(&irq.irq255)));
    entry(207, @as(usize, @intFromPtr(&irq.irq255)));
    entry(208, @as(usize, @intFromPtr(&irq.irq255)));
    entry(209, @as(usize, @intFromPtr(&irq.irq255)));
    entry(210, @as(usize, @intFromPtr(&irq.irq255)));
    entry(211, @as(usize, @intFromPtr(&irq.irq255)));
    entry(212, @as(usize, @intFromPtr(&irq.irq255)));
    entry(213, @as(usize, @intFromPtr(&irq.irq255)));
    entry(214, @as(usize, @intFromPtr(&irq.irq255)));
    entry(215, @as(usize, @intFromPtr(&irq.irq255)));
    entry(216, @as(usize, @intFromPtr(&irq.irq255)));
    entry(217, @as(usize, @intFromPtr(&irq.irq255)));
    entry(218, @as(usize, @intFromPtr(&irq.irq255)));
    entry(219, @as(usize, @intFromPtr(&irq.irq255)));
    entry(220, @as(usize, @intFromPtr(&irq.irq255)));
    entry(221, @as(usize, @intFromPtr(&irq.irq255)));
    entry(222, @as(usize, @intFromPtr(&irq.irq255)));
    entry(223, @as(usize, @intFromPtr(&irq.irq255)));
    entry(224, @as(usize, @intFromPtr(&irq.irq255)));
    entry(225, @as(usize, @intFromPtr(&irq.irq255)));
    entry(226, @as(usize, @intFromPtr(&irq.irq255)));
    entry(227, @as(usize, @intFromPtr(&irq.irq255)));
    entry(228, @as(usize, @intFromPtr(&irq.irq255)));
    entry(229, @as(usize, @intFromPtr(&irq.irq255)));
    entry(230, @as(usize, @intFromPtr(&irq.irq255)));
    entry(231, @as(usize, @intFromPtr(&irq.irq255)));
    entry(232, @as(usize, @intFromPtr(&irq.irq255)));
    entry(233, @as(usize, @intFromPtr(&irq.irq255)));
    entry(234, @as(usize, @intFromPtr(&irq.irq255)));
    entry(235, @as(usize, @intFromPtr(&irq.irq255)));
    entry(236, @as(usize, @intFromPtr(&irq.irq255)));
    entry(237, @as(usize, @intFromPtr(&irq.irq255)));
    entry(238, @as(usize, @intFromPtr(&irq.irq255)));
    entry(239, @as(usize, @intFromPtr(&irq.irq255)));
    entry(240, @as(usize, @intFromPtr(&irq.irq255)));
    entry(241, @as(usize, @intFromPtr(&irq.irq255)));
    entry(242, @as(usize, @intFromPtr(&irq.irq255)));
    entry(243, @as(usize, @intFromPtr(&irq.irq255)));
    entry(244, @as(usize, @intFromPtr(&irq.irq255)));
    entry(245, @as(usize, @intFromPtr(&irq.irq255)));
    entry(246, @as(usize, @intFromPtr(&irq.irq255)));
    entry(247, @as(usize, @intFromPtr(&irq.irq255)));
    entry(248, @as(usize, @intFromPtr(&irq.irq255)));
    entry(249, @as(usize, @intFromPtr(&irq.irq255)));
    entry(250, @as(usize, @intFromPtr(&irq.irq255)));
    entry(251, @as(usize, @intFromPtr(&irq.irq255)));
    entry(252, @as(usize, @intFromPtr(&irq.irq255)));
    entry(253, @as(usize, @intFromPtr(&irq.irq255)));
    entry(254, @as(usize, @intFromPtr(&irq.irq255)));
    entry(255, @as(usize, @intFromPtr(&irq.irq255)));
}
