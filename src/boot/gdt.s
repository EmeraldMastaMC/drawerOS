#GDT
gdt_start: # Null Descriptor
  .long 0x00000000
  .long 0x00000000

gdt_code:# Code Descriptor
  .word 0xFFFF        # Limit                 0-15
  .word 0x0000        # Base                  16 -31
  .byte 0x00          # Base                  32 - 39
  .byte 0b10011010    # 1st flags, Type flags 40 - 47
  .byte 0b11001111    # 2nd flags, Limit      48 - 55
  .byte 0x00          # Base                  56 - 63

gdt_data: # Data Descriptor
  .word 0xFFFF        # Limit                 0-15
  .word 0x0000        # Base                  16 -31
  .byte 0x00          # Base                  32 - 39
  .byte 0b10010010    # 1st flags, Type flags 40 - 47
  .byte 0b11001111    # 2nd flags, Limit      48 - 55
  .byte 0x00          # Base                  56 - 63
gdt_end:
gdt_descriptor:
  .word (gdt_end - gdt_start - 1)
  .long gdt_start

.equ CODE_SEG, (gdt_code - gdt_start)
.equ DATA_SEG, (gdt_data - gdt_start)

gdt_start64: # Null Descriptor
  .long 0x00000000
  .long 0x00000000

gdt_code64:# Code Descriptor
  .word 0xFFFF        # Limit                 0-15
  .word 0x0000        # Base                  16 -31
  .byte 0x00          # Base                  32 - 39
  .byte 0b10011010    # 1st flags, Type flags 40 - 47
  .byte 0b10101111    # 2nd flags, Limit      48 - 55
  .byte 0x00          # Base                  56 - 63

gdt_data64: # Data Descriptor
  .word 0xFFFF        # Limit                 0-15
  .word 0x0000        # Base                  16 -31
  .byte 0x00          # Base                  32 - 39
  .byte 0b10010010    # 1st flags, Type flags 40 - 47
  .byte 0b10101111    # 2nd flags, Limit      48 - 55
  .byte 0x00          # Base                  56 - 63
gdt_tss64:
  .long 0x00000068
  .long 0x00CF8900
gdt_end64:
gdt_descriptor64:
  .word (gdt_end64 - gdt_start64 - 1)
  .quad gdt_start64

.equ CODE_SEG64, (gdt_code64 - gdt_start64)
.equ DATA_SEG64, (gdt_data64 - gdt_start64)
