.include "src/boot/gdt.s"
.extern start
.code16
start_pm: # Start 32 bit mode

  # Load the GDT
  cli
  lgdt gdt_descriptor
  movl %cr0, %eax
  orl $0x1, %eax
  movl %eax, %cr0

  jmp $CODE_SEG, $start_of_pm

.code32
start_of_pm: # This is where 32 bit mode starts
  cli
  movw $DATA_SEG, %ax
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs
  movw %ax, %gs
  movw %ax, %ss

  call enable_paging
  lgdt gdt_descriptor64
  ljmp $CODE_SEG64, $begin_lm
  hlt

.equ PageTableEntry, 0x1000

# Ripped from https://wiki.osdev.org/Paging
enable_paging:
  movl $PageTableEntry, %edi
  movl %edi, %cr3

  movl $0x2003, (%edi)
  addl $0x1000, %edi
  movl $0x3003, (%edi)
  addl $0x1000, %edi
  movl $0x4003, (%edi)
  addl $0x1000, %edi

  movl $0x00000003, %ebx
  movl $512, %ecx

  set_entry:
    movl %ebx, (%edi)
    addl $0x1000, %ebx
    addl $8, %edi
    loop set_entry

  movl %cr4, %eax
  orl $0x20, %eax
  movl %eax, %cr4

  movl $0xC0000080, %ecx
  rdmsr
  orl $0x100, %eax
  wrmsr

  movl %cr0, %eax
  orl $0x80000000, %eax
  movl %eax, %cr0
  ret 



.code64
begin_lm:
  cli
  movw $DATA_SEG64, %ax
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs
  movw %ax, %gs
  movw %ax, %ss
  jmp KERNEL_START
  cli
  hlt
