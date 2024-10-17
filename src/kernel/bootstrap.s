.globl start
.extern main
.section .bootstrap
start:
  call main
  cli
  hlt

