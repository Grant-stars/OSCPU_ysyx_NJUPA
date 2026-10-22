#include "include/ysyxsoc.h"
#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
extern char _sram_start;
#define SRAM_SIZE 0x2000
#define SRAM_END  ((uintptr_t)&_sram_start + SRAM_SIZE)
#define nemu_trap(code) asm volatile ("mv a0, %0; ebreak;": : "r"(code))

Area heap = RANGE(&_heap_start, SRAM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
  outb(UART_ADDR, ch);
}

void halt(int code) {
  nemu_trap(code);
  while(1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}
