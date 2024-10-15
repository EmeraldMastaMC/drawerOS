.code16
.globl _start
.section .boot

.extern KERNEL_START

_start:


  # Load the kernel from disk to KERNEL_START
  xor %ax, %ax
  movw %ax, %ds
  movw %ax, %ss
  movw %ax, %es
  movw %ax, %ss
  movw $0x7C00, %sp

  movb $0x02, %ah          # BIOS read sector function
  movb $0x40, %al             # Sectors to load
  movb $0x00, %ch          # Select cylinder 0
  movb $0x00, %dh          # Select Head 0
  movb $0x02, %cl          # Start reading from the second sector (the sector after the boot sector)
  # movb $0x00, %dl          # Which drive we load our kernel from
  movw $KERNEL_START, %bx        # Where to load our kernel
  int $0x13                # Disk read bios interrupt

  # A20 Line
  inb $0x92, %al
  orb $2, %al
  outb %al, $0x92

  jmp start_pm
  .include "./src/boot/load64bit.s"


.code16
.org 510
.word 0xAA55

