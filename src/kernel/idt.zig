const cpu = @import("cpu.zig");
const irq = @import("irq.zig");

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
    cpu.sti();

    return;
}

pub inline fn initEntries() void {
    entry(1, @as(usize, @intFromPtr(&irq.irqret)));
    entry(2, @as(usize, @intFromPtr(&irq.irqret)));
    entry(3, @as(usize, @intFromPtr(&irq.irqret)));
    entry(4, @as(usize, @intFromPtr(&irq.irqret)));
    entry(5, @as(usize, @intFromPtr(&irq.irqret)));
    entry(6, @as(usize, @intFromPtr(&irq.irqret)));
    entry(7, @as(usize, @intFromPtr(&irq.irqret)));
    entry(8, @as(usize, @intFromPtr(&irq.irqret)));
    entry(9, @as(usize, @intFromPtr(&irq.irqret)));
    entry(10, @as(usize, @intFromPtr(&irq.irqret)));
    entry(11, @as(usize, @intFromPtr(&irq.irqret)));
    entry(12, @as(usize, @intFromPtr(&irq.irqret)));
    entry(13, @as(usize, @intFromPtr(&irq.irqret)));
    entry(14, @as(usize, @intFromPtr(&irq.irqret)));
    entry(15, @as(usize, @intFromPtr(&irq.irqret)));
    entry(16, @as(usize, @intFromPtr(&irq.irqret)));
    entry(17, @as(usize, @intFromPtr(&irq.irqret)));
    entry(18, @as(usize, @intFromPtr(&irq.irqret)));
    entry(19, @as(usize, @intFromPtr(&irq.irqret)));
    entry(20, @as(usize, @intFromPtr(&irq.irqret)));
    entry(21, @as(usize, @intFromPtr(&irq.irqret)));
    entry(22, @as(usize, @intFromPtr(&irq.irqret)));
    entry(23, @as(usize, @intFromPtr(&irq.irqret)));
    entry(24, @as(usize, @intFromPtr(&irq.irqret)));
    entry(25, @as(usize, @intFromPtr(&irq.irqret)));
    entry(26, @as(usize, @intFromPtr(&irq.irqret)));
    entry(27, @as(usize, @intFromPtr(&irq.irqret)));
    entry(28, @as(usize, @intFromPtr(&irq.irqret)));
    entry(29, @as(usize, @intFromPtr(&irq.irqret)));
    entry(30, @as(usize, @intFromPtr(&irq.irqret)));
    entry(31, @as(usize, @intFromPtr(&irq.irqret)));
    entry(32, @as(usize, @intFromPtr(&irq.irq32)));
    entry(33, @as(usize, @intFromPtr(&irq.irqret)));
    entry(34, @as(usize, @intFromPtr(&irq.irqret)));
    entry(35, @as(usize, @intFromPtr(&irq.irqret)));
    entry(36, @as(usize, @intFromPtr(&irq.irqret)));
    entry(37, @as(usize, @intFromPtr(&irq.irqret)));
    entry(38, @as(usize, @intFromPtr(&irq.irqret)));
    entry(39, @as(usize, @intFromPtr(&irq.irqret)));
    entry(40, @as(usize, @intFromPtr(&irq.irqret)));
    entry(41, @as(usize, @intFromPtr(&irq.irqret)));
    entry(42, @as(usize, @intFromPtr(&irq.irqret)));
    entry(43, @as(usize, @intFromPtr(&irq.irqret)));
    entry(44, @as(usize, @intFromPtr(&irq.irqret)));
    entry(45, @as(usize, @intFromPtr(&irq.irqret)));
    entry(46, @as(usize, @intFromPtr(&irq.irqret)));
    entry(47, @as(usize, @intFromPtr(&irq.irqret)));
    entry(48, @as(usize, @intFromPtr(&irq.irqret)));
    entry(49, @as(usize, @intFromPtr(&irq.irqret)));
    entry(50, @as(usize, @intFromPtr(&irq.irqret)));
    entry(51, @as(usize, @intFromPtr(&irq.irqret)));
    entry(52, @as(usize, @intFromPtr(&irq.irqret)));
    entry(53, @as(usize, @intFromPtr(&irq.irqret)));
    entry(54, @as(usize, @intFromPtr(&irq.irqret)));
    entry(55, @as(usize, @intFromPtr(&irq.irqret)));
    entry(56, @as(usize, @intFromPtr(&irq.irqret)));
    entry(57, @as(usize, @intFromPtr(&irq.irqret)));
    entry(58, @as(usize, @intFromPtr(&irq.irqret)));
    entry(59, @as(usize, @intFromPtr(&irq.irqret)));
    entry(60, @as(usize, @intFromPtr(&irq.irqret)));
    entry(61, @as(usize, @intFromPtr(&irq.irqret)));
    entry(62, @as(usize, @intFromPtr(&irq.irqret)));
    entry(63, @as(usize, @intFromPtr(&irq.irqret)));
    entry(64, @as(usize, @intFromPtr(&irq.irqret)));
    entry(65, @as(usize, @intFromPtr(&irq.irqret)));
    entry(66, @as(usize, @intFromPtr(&irq.irqret)));
    entry(67, @as(usize, @intFromPtr(&irq.irqret)));
    entry(68, @as(usize, @intFromPtr(&irq.irqret)));
    entry(69, @as(usize, @intFromPtr(&irq.irqret)));
    entry(70, @as(usize, @intFromPtr(&irq.irqret)));
    entry(71, @as(usize, @intFromPtr(&irq.irqret)));
    entry(72, @as(usize, @intFromPtr(&irq.irqret)));
    entry(73, @as(usize, @intFromPtr(&irq.irqret)));
    entry(74, @as(usize, @intFromPtr(&irq.irqret)));
    entry(75, @as(usize, @intFromPtr(&irq.irqret)));
    entry(76, @as(usize, @intFromPtr(&irq.irqret)));
    entry(77, @as(usize, @intFromPtr(&irq.irqret)));
    entry(78, @as(usize, @intFromPtr(&irq.irqret)));
    entry(79, @as(usize, @intFromPtr(&irq.irqret)));
    entry(80, @as(usize, @intFromPtr(&irq.irqret)));
    entry(81, @as(usize, @intFromPtr(&irq.irqret)));
    entry(82, @as(usize, @intFromPtr(&irq.irqret)));
    entry(83, @as(usize, @intFromPtr(&irq.irqret)));
    entry(84, @as(usize, @intFromPtr(&irq.irqret)));
    entry(85, @as(usize, @intFromPtr(&irq.irqret)));
    entry(86, @as(usize, @intFromPtr(&irq.irqret)));
    entry(87, @as(usize, @intFromPtr(&irq.irqret)));
    entry(88, @as(usize, @intFromPtr(&irq.irqret)));
    entry(89, @as(usize, @intFromPtr(&irq.irqret)));
    entry(90, @as(usize, @intFromPtr(&irq.irqret)));
    entry(91, @as(usize, @intFromPtr(&irq.irqret)));
    entry(92, @as(usize, @intFromPtr(&irq.irqret)));
    entry(93, @as(usize, @intFromPtr(&irq.irqret)));
    entry(94, @as(usize, @intFromPtr(&irq.irqret)));
    entry(95, @as(usize, @intFromPtr(&irq.irqret)));
    entry(96, @as(usize, @intFromPtr(&irq.irqret)));
    entry(97, @as(usize, @intFromPtr(&irq.irqret)));
    entry(98, @as(usize, @intFromPtr(&irq.irqret)));
    entry(99, @as(usize, @intFromPtr(&irq.irqret)));
    entry(100, @as(usize, @intFromPtr(&irq.irqret)));
    entry(101, @as(usize, @intFromPtr(&irq.irqret)));
    entry(102, @as(usize, @intFromPtr(&irq.irqret)));
    entry(103, @as(usize, @intFromPtr(&irq.irqret)));
    entry(104, @as(usize, @intFromPtr(&irq.irqret)));
    entry(105, @as(usize, @intFromPtr(&irq.irqret)));
    entry(106, @as(usize, @intFromPtr(&irq.irqret)));
    entry(107, @as(usize, @intFromPtr(&irq.irqret)));
    entry(108, @as(usize, @intFromPtr(&irq.irqret)));
    entry(109, @as(usize, @intFromPtr(&irq.irqret)));
    entry(110, @as(usize, @intFromPtr(&irq.irqret)));
    entry(111, @as(usize, @intFromPtr(&irq.irqret)));
    entry(112, @as(usize, @intFromPtr(&irq.irqret)));
    entry(113, @as(usize, @intFromPtr(&irq.irqret)));
    entry(114, @as(usize, @intFromPtr(&irq.irqret)));
    entry(115, @as(usize, @intFromPtr(&irq.irqret)));
    entry(116, @as(usize, @intFromPtr(&irq.irqret)));
    entry(117, @as(usize, @intFromPtr(&irq.irqret)));
    entry(118, @as(usize, @intFromPtr(&irq.irqret)));
    entry(119, @as(usize, @intFromPtr(&irq.irqret)));
    entry(120, @as(usize, @intFromPtr(&irq.irqret)));
    entry(121, @as(usize, @intFromPtr(&irq.irqret)));
    entry(122, @as(usize, @intFromPtr(&irq.irqret)));
    entry(123, @as(usize, @intFromPtr(&irq.irqret)));
    entry(124, @as(usize, @intFromPtr(&irq.irqret)));
    entry(125, @as(usize, @intFromPtr(&irq.irqret)));
    entry(126, @as(usize, @intFromPtr(&irq.irqret)));
    entry(127, @as(usize, @intFromPtr(&irq.irqret)));
    entry(128, @as(usize, @intFromPtr(&irq.irqret)));
    entry(129, @as(usize, @intFromPtr(&irq.irqret)));
    entry(130, @as(usize, @intFromPtr(&irq.irqret)));
    entry(131, @as(usize, @intFromPtr(&irq.irqret)));
    entry(132, @as(usize, @intFromPtr(&irq.irqret)));
    entry(133, @as(usize, @intFromPtr(&irq.irqret)));
    entry(134, @as(usize, @intFromPtr(&irq.irqret)));
    entry(135, @as(usize, @intFromPtr(&irq.irqret)));
    entry(136, @as(usize, @intFromPtr(&irq.irqret)));
    entry(137, @as(usize, @intFromPtr(&irq.irqret)));
    entry(138, @as(usize, @intFromPtr(&irq.irqret)));
    entry(139, @as(usize, @intFromPtr(&irq.irqret)));
    entry(140, @as(usize, @intFromPtr(&irq.irqret)));
    entry(141, @as(usize, @intFromPtr(&irq.irqret)));
    entry(142, @as(usize, @intFromPtr(&irq.irqret)));
    entry(143, @as(usize, @intFromPtr(&irq.irqret)));
    entry(144, @as(usize, @intFromPtr(&irq.irqret)));
    entry(145, @as(usize, @intFromPtr(&irq.irqret)));
    entry(146, @as(usize, @intFromPtr(&irq.irqret)));
    entry(147, @as(usize, @intFromPtr(&irq.irqret)));
    entry(148, @as(usize, @intFromPtr(&irq.irqret)));
    entry(149, @as(usize, @intFromPtr(&irq.irqret)));
    entry(150, @as(usize, @intFromPtr(&irq.irqret)));
    entry(151, @as(usize, @intFromPtr(&irq.irqret)));
    entry(152, @as(usize, @intFromPtr(&irq.irqret)));
    entry(153, @as(usize, @intFromPtr(&irq.irqret)));
    entry(154, @as(usize, @intFromPtr(&irq.irqret)));
    entry(155, @as(usize, @intFromPtr(&irq.irqret)));
    entry(156, @as(usize, @intFromPtr(&irq.irqret)));
    entry(157, @as(usize, @intFromPtr(&irq.irqret)));
    entry(158, @as(usize, @intFromPtr(&irq.irqret)));
    entry(159, @as(usize, @intFromPtr(&irq.irqret)));
    entry(160, @as(usize, @intFromPtr(&irq.irqret)));
    entry(161, @as(usize, @intFromPtr(&irq.irqret)));
    entry(162, @as(usize, @intFromPtr(&irq.irqret)));
    entry(163, @as(usize, @intFromPtr(&irq.irqret)));
    entry(164, @as(usize, @intFromPtr(&irq.irqret)));
    entry(165, @as(usize, @intFromPtr(&irq.irqret)));
    entry(166, @as(usize, @intFromPtr(&irq.irqret)));
    entry(167, @as(usize, @intFromPtr(&irq.irqret)));
    entry(168, @as(usize, @intFromPtr(&irq.irqret)));
    entry(169, @as(usize, @intFromPtr(&irq.irqret)));
    entry(170, @as(usize, @intFromPtr(&irq.irqret)));
    entry(171, @as(usize, @intFromPtr(&irq.irqret)));
    entry(172, @as(usize, @intFromPtr(&irq.irqret)));
    entry(173, @as(usize, @intFromPtr(&irq.irqret)));
    entry(174, @as(usize, @intFromPtr(&irq.irqret)));
    entry(175, @as(usize, @intFromPtr(&irq.irqret)));
    entry(176, @as(usize, @intFromPtr(&irq.irqret)));
    entry(177, @as(usize, @intFromPtr(&irq.irqret)));
    entry(178, @as(usize, @intFromPtr(&irq.irqret)));
    entry(179, @as(usize, @intFromPtr(&irq.irqret)));
    entry(180, @as(usize, @intFromPtr(&irq.irqret)));
    entry(181, @as(usize, @intFromPtr(&irq.irqret)));
    entry(182, @as(usize, @intFromPtr(&irq.irqret)));
    entry(183, @as(usize, @intFromPtr(&irq.irqret)));
    entry(184, @as(usize, @intFromPtr(&irq.irqret)));
    entry(185, @as(usize, @intFromPtr(&irq.irqret)));
    entry(186, @as(usize, @intFromPtr(&irq.irqret)));
    entry(187, @as(usize, @intFromPtr(&irq.irqret)));
    entry(188, @as(usize, @intFromPtr(&irq.irqret)));
    entry(189, @as(usize, @intFromPtr(&irq.irqret)));
    entry(190, @as(usize, @intFromPtr(&irq.irqret)));
    entry(191, @as(usize, @intFromPtr(&irq.irqret)));
    entry(192, @as(usize, @intFromPtr(&irq.irqret)));
    entry(193, @as(usize, @intFromPtr(&irq.irqret)));
    entry(194, @as(usize, @intFromPtr(&irq.irqret)));
    entry(195, @as(usize, @intFromPtr(&irq.irqret)));
    entry(196, @as(usize, @intFromPtr(&irq.irqret)));
    entry(197, @as(usize, @intFromPtr(&irq.irqret)));
    entry(198, @as(usize, @intFromPtr(&irq.irqret)));
    entry(199, @as(usize, @intFromPtr(&irq.irqret)));
    entry(200, @as(usize, @intFromPtr(&irq.irqret)));
    entry(201, @as(usize, @intFromPtr(&irq.irqret)));
    entry(202, @as(usize, @intFromPtr(&irq.irqret)));
    entry(203, @as(usize, @intFromPtr(&irq.irqret)));
    entry(204, @as(usize, @intFromPtr(&irq.irqret)));
    entry(205, @as(usize, @intFromPtr(&irq.irqret)));
    entry(206, @as(usize, @intFromPtr(&irq.irqret)));
    entry(207, @as(usize, @intFromPtr(&irq.irqret)));
    entry(208, @as(usize, @intFromPtr(&irq.irqret)));
    entry(209, @as(usize, @intFromPtr(&irq.irqret)));
    entry(210, @as(usize, @intFromPtr(&irq.irqret)));
    entry(211, @as(usize, @intFromPtr(&irq.irqret)));
    entry(212, @as(usize, @intFromPtr(&irq.irqret)));
    entry(213, @as(usize, @intFromPtr(&irq.irqret)));
    entry(214, @as(usize, @intFromPtr(&irq.irqret)));
    entry(215, @as(usize, @intFromPtr(&irq.irqret)));
    entry(216, @as(usize, @intFromPtr(&irq.irqret)));
    entry(217, @as(usize, @intFromPtr(&irq.irqret)));
    entry(218, @as(usize, @intFromPtr(&irq.irqret)));
    entry(219, @as(usize, @intFromPtr(&irq.irqret)));
    entry(220, @as(usize, @intFromPtr(&irq.irqret)));
    entry(221, @as(usize, @intFromPtr(&irq.irqret)));
    entry(222, @as(usize, @intFromPtr(&irq.irqret)));
    entry(223, @as(usize, @intFromPtr(&irq.irqret)));
    entry(224, @as(usize, @intFromPtr(&irq.irqret)));
    entry(225, @as(usize, @intFromPtr(&irq.irqret)));
    entry(226, @as(usize, @intFromPtr(&irq.irqret)));
    entry(227, @as(usize, @intFromPtr(&irq.irqret)));
    entry(228, @as(usize, @intFromPtr(&irq.irqret)));
    entry(229, @as(usize, @intFromPtr(&irq.irqret)));
    entry(230, @as(usize, @intFromPtr(&irq.irqret)));
    entry(231, @as(usize, @intFromPtr(&irq.irqret)));
    entry(232, @as(usize, @intFromPtr(&irq.irqret)));
    entry(233, @as(usize, @intFromPtr(&irq.irqret)));
    entry(234, @as(usize, @intFromPtr(&irq.irqret)));
    entry(235, @as(usize, @intFromPtr(&irq.irqret)));
    entry(236, @as(usize, @intFromPtr(&irq.irqret)));
    entry(237, @as(usize, @intFromPtr(&irq.irqret)));
    entry(238, @as(usize, @intFromPtr(&irq.irqret)));
    entry(239, @as(usize, @intFromPtr(&irq.irqret)));
    entry(240, @as(usize, @intFromPtr(&irq.irqret)));
    entry(241, @as(usize, @intFromPtr(&irq.irqret)));
    entry(242, @as(usize, @intFromPtr(&irq.irqret)));
    entry(243, @as(usize, @intFromPtr(&irq.irqret)));
    entry(244, @as(usize, @intFromPtr(&irq.irqret)));
    entry(245, @as(usize, @intFromPtr(&irq.irqret)));
    entry(246, @as(usize, @intFromPtr(&irq.irqret)));
    entry(247, @as(usize, @intFromPtr(&irq.irqret)));
    entry(248, @as(usize, @intFromPtr(&irq.irqret)));
    entry(249, @as(usize, @intFromPtr(&irq.irqret)));
    entry(250, @as(usize, @intFromPtr(&irq.irqret)));
    entry(251, @as(usize, @intFromPtr(&irq.irqret)));
    entry(252, @as(usize, @intFromPtr(&irq.irqret)));
    entry(253, @as(usize, @intFromPtr(&irq.irqret)));
    entry(254, @as(usize, @intFromPtr(&irq.irqret)));
    entry(255, @as(usize, @intFromPtr(&irq.irqret)));
}
