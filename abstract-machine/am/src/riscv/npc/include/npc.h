#ifndef __NPC_H__
#define __NPC_H__

#include <stdint.h>

#define CLOCK_ADDR        0x02000000
#define RTC_ADDR          0x02000000
#define UPTIME_ADDR       (CLOCK_ADDR + 8)

#define SERIAL_PORT 0x10000000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

#endif