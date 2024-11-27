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
  ljmp $0x00, $next
next:
  # movb $0x02, %ah          # BIOS read sector function
  # movb $0x40, %al             # Sectors to load
  # movb $0x00, %ch          # Select cylinder 0
  # movb $0x00, %dh          # Select Head 0
  # movb $0x02, %cl          # Start reading from the second sector (the sector after the boot sector)
  # movb $0x80, %dl          # Which drive we load our kernel from
  # movw $KERNEL_START, %bx        # Where to load our kernel
  # int $0x13                # Disk read bios interrupt

  # A20 Line
  inb $0x92, %al
  orb $2, %al
  outb %al, $0x92

  # 1
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 2
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 3
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 4
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 5
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 6
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 7
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  # 8
  addw $0x1000, (memseg)
  addl $0x80, (lba)
  movw $diskaddress_packet, %si
  movb $0x42, %ah
  movb $0x80, %dl
  int $0x13

  jmp start_pm
  .include "./src/boot/load64bit.s"

.code16
not_supp:
  cli 
  hlt

.align 4 
diskaddress_packet:
  .byte 0x10
  .byte 0x00
blockcnt: 
  .word 0x80
memoffset:
  .word 0x7E00
memseg:
  .word 0x00
lba:
  .long 0x01
  .long 0x00

.align 4 
diskaddress_packet2:
  .byte 0x10
  .byte 0x00
  .word 0x80
  .word 0x7E00
  .word 0x1000
  .long 0x81
  .long 0x00

.org 510
.word 0xAA55

