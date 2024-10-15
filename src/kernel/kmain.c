#include <stdint.h>
#include <stdbool.h>

void main() {
  int16_t* VIDEO_MEMORY = (int16_t*)0xB8000;
  VIDEO_MEMORY[0] = 0x0F00 | (int16_t)'X';
  while (true) {}
}

