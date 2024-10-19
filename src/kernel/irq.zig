const isr = @import("isr.zig");
pub const Frame = extern struct {
    es: u64,
    ds: u64,

    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rsi: u64,
    rdi: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,
    rbp: u64,
};

pub fn irq32() callconv(.Naked) void {
    asm volatile (
        \\ push %rbp
        \\ push %rax
        \\ push %rbx
        \\ push %rcx
        \\ push %rdx
        \\ push %rdi
        \\ push %rsi
        \\ push %r8
        \\ push %r9
        \\ push %r10
        \\ push %r11
        \\ push %r12
        \\ push %r13
        \\ push %r14
        \\ push %r15
        \\ movq %ds, %rax
        \\ push %rax
        \\ movq %es, %rax
        \\ push %rax
        \\ movw $0x10, %ax
        \\ movw %ax, %ds
        \\ movw %ax, %es
        \\ cld
        \\ call print
        \\ pop %rax
        \\ movq %rax, %es
        \\ pop %rax
        \\ movq %rax, %ds
        \\ pop %r15
        \\ pop %r14
        \\ pop %r13
        \\ pop %r12
        \\ pop %r11
        \\ pop %r10
        \\ pop %r9
        \\ pop %r8
        \\ pop %rsi
        \\ pop %rdi
        \\ pop %rdx
        \\ pop %rcx
        \\ pop %rbx
        \\ pop %rax
        \\ pop %rbp
        \\ iretq
    );
}
