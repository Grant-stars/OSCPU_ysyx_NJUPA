
#ifndef __MEMORY_SOC_H__
#define __MEMORY_SOC_H__

#include <common.h>

#define MROM_VECTOR		0x20000000
#define MROM_SIZE		0x1000

#define SRAM_VECTOR		0x0f000000
#define SRAM_SIZE		0x0f001fff

static inline bool in_mrom(paddr_t addr) {
  return addr - MROM_VECTOR < MROM_SIZE;
}

static inline bool in_sram(paddr_t addr) {
  return addr - SRAM_VECTOR < SRAM_SIZE;
}

uint8_t* mrom_to_host(paddr_t paddr);
uint8_t* sram_to_host(paddr_t paddr);

word_t mrom_read(paddr_t addr, int len);
word_t sram_read(paddr_t addr, int len);

void mrom_write(paddr_t addr, int len, word_t data);
void sram_write(paddr_t addr, int len, word_t data);

#endif
