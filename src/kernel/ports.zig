pub inline fn outb(port: u16, value: u8) void {
    asm volatile (
        \\ outb %[value], %[port]
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inb(port: u16) u8 {
    var result: u8 = undefined;
    asm volatile (
        \\ inb %[port], %[result]
        : [result] "={al}" (result),
        : [port] "{dx}" (port),
    );
    return result;
}

pub inline fn outw(port: u16, value: u16) void {
    asm volatile (
        \\ outw %[value], %[port]
        :
        : [value] "{ax}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inw(port: u16) u16 {
    var result: u16 = undefined;
    asm volatile (
        \\ inw %[port], %[result]
        : [result] "={ax}" (result),
        : [port] "{dx}" (port),
    );
    return result;
}

pub inline fn outl(port: u16, value: u32) void {
    asm volatile (
        \\ outl %[value], %[port]
        :
        : [value] "{eax}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inl(port: u16) u32 {
    var result: u32 = undefined;
    asm volatile (
        \\ inl %[port], %[result]
        : [result] "={eax}" (result),
        : [port] "{dx}" (port),
    );
    return result;
}

pub inline fn outq(port: u16, value: u64) void {
    asm volatile (
        \\ outq %[value], %[port]
        :
        : [value] "{rax}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inq(port: u16) u64 {
    var result: u64 = undefined;
    asm volatile (
        \\ inq %[port], %[result]
        : [result] "={rax}" (result),
        : [port] "{dx}" (port),
    );
    return result;
}
