// See the Registers part of the Preface section of the manual for a list of all registers and an overview of what they are used for.
// See figure 1-7 in section 1.4 of the manual for a list of all System Registers.

// CPU state that needs to be saved and restored
pub const Context = extern struct {
    // Segment registers. These aren't used in 64 bit mode. We use cr3 to control the page table
    es: u64 = 0, // Extra segment register, typically used in segmented memory addressing, Should be zero in 64 bit mode.
    ds: u64 = 0, // Data segment register, also used in segmented memory addressing. Should be zero in 64 bit mode.

    r15: u64 = 0, // General Purpose Register
    r14: u64 = 0, // General Purpose Register
    r13: u64 = 0, // General Purpose Register
    r12: u64 = 0, // General Purpose Register
    r11: u64 = 0, // General Purpose Register
    r10: u64 = 0, // General Purpose Register
    r9: u64 = 0, // General Purpose Register
    r8: u64 = 0, // General Purpose Register
    rsi: u64 = 0, // Source Index register, used as a pointer in array/string operatings
    rdi: u64 = 0, // Destination Index register, also used to store a pointer in array/string operatings
    rdx: u64 = 0, // Data register, used in I/O operations and arithmetic operations
    rcx: u64 = 0, // Counter register, used in loop operations and shift/rotate instructions
    rbx: u64 = 0, // Base Register, sometimes used to store a pointer to data
    rax: u64 = 0, // Accumulator register, often used in arithmetic operations

    rbp: u64 = 0, // Base Pointer register. points the the base of the current stack frame.
    rip: u64 = 0, // Instruction pointer, points to the next instruction to be executed.
    cs: u64 = 0, // Code segment register.
    rflags: u64 = 0, // Flags register, holds the status flags and control flags
    rsp: u64 = 0, // Stack Pointer register. Points to the top of the current stack
    ss: u64 = 0, // Stack segment register, contains the segment selector for the stack segment
};

// Model specific register
pub const msr = struct {
    pub inline fn write(register: usize, value: usize) void {
        const lo: u32 = @truncate(value);
        const hi: u32 = @truncate(value >> 32);

        asm volatile ("wrmsr"
            :
            : [register] "{ecx}" (register),
              [value_low] "{eax}" (lo),
              [value_high] "{edx}" (hi),
        );
    }

    pub inline fn read(register: usize) u64 {
        const lo: u32 = undefined;
        const hi: u32 = undefined;

        asm volatile ("rdmsr"
            :
            : [register] "{ecx}" (register),
              [value_low] "={eax}" (lo),
              [value_high] "={edx}" (hi),
        );

        return (@as(usize, hi) << 32) | lo;
    }
};

// Control register (points to the page L4 page table directory)
// See section 5.3.2 of the manual for in depth information regarding the cr3 register
pub const cr3 = struct {
    pub inline fn write(value: u64) void {
        asm volatile ("movq %[value], %cr3"
            :
            : [value] "{rbx}" (value),
            : "memory"
        );
    }

    pub inline fn read() u64 {
        return asm volatile ("movq %cr3, %[result]"
            : [result] "={rbx}" (-> u64),
        );
    }
};

// Control register (contains flags for the CPU)
// See section 3.1.3 of the manual for in depth information regarding the cr4 register
pub const cr4 = struct {
    pub inline fn write(value: u64) void {
        asm volatile ("mov %[value], %cr4"
            :
            : [value] "{rax}" (value),
            : "memory"
        );
    }

    pub inline fn read() u64 {
        return asm volatile ("mov %cr4, %[result]"
            : [result] "={rax}" (-> u64),
        );
    }
};

pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "=r" (-> u16),
    );
}

pub inline fn getSS() u16 {
    return asm volatile ("mov %ss, %[result]"
        : [result] "=r" (-> u16),
    );
}

pub inline fn cli() void {
    asm volatile ("cli");
}

pub inline fn sti() void {
    asm volatile ("sti");
}

// See section 4.6 of the manual for information regarding Descriptor Tables

// See section 4.6.5 of the manual for information regarding the Interrupt Descriptor Table
// Loads the Interrupt Descriptor Table
pub inline fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}

// See section 4.6.1 of the manual for information regarding the Global Descriptor Table
// Loads the Global Descriptor Table
pub inline fn lgdt(gdtr: u80) void {
    asm volatile ("lgdt %[p]"
        :
        : [p] "*p" (&gdtr),
    );
}

pub inline fn hlt() void {
    asm volatile ("hlt");
}
