.code16
.globl _start
.text
_start:
  cli
  hlt
.org 510
.word 0xAA55
