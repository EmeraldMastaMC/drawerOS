OUTPUT_FORMAT(binary)

BOOT_START = 0x7C00;
SECT_SIZE = 0x200;
KERNEL_START = 0x7E00;
SECTIONS
{
  . = BOOT_START;
  .text :
  {
    *(.boot)
    *(.bootstrap)
    . = 0x2000;
    *(.text)
  }
  .data :
  {
    *(.data)
  }
  .bss :
  {
    *(.bss)
  }
}
