.code64
.section .bootstrap
.globl start
start:
  call main
  cli
  hlt
