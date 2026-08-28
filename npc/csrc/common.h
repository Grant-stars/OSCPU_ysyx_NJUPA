#ifndef __COMMON_H__
#define __COMMON_H__
#include <stdint.h>
#include <stdlib.h>
#include  <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "include/debug.h"
#include <inttypes.h>

#define CONFIG_MSIZE (1U<<30)
#define CONFIG_MBASE 0x80000000
#define PMEM_LEFT  ((uint32_t)CONFIG_MBASE)
#define PMEM_RIGHT ((uint32_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
#define CONFIG_PC_RESET_OFFSET 0x0
#define RESET_VECTOR (PMEM_LEFT + CONFIG_PC_RESET_OFFSET)


uint8_t* guest_to_host(uint32_t paddr);


typedef uint32_t word_t; 

#define FMT_WORD "0x%08" PRIx32
#define FMT_PADDR "0x%08" PRIx32

#define CONFIG_TRACE 1
#ifdef CONFIG_TRACE

//#define CONFIG_ITRACE 1
//#define CONFIG_MTRACE 1
#define CONFIG_FTRACE 1
//#define CONFIG_DTRACE 1
//#define CONFIG_WATCHPOINT

#endif

//#define CONFIG_DIFFTEST 1

#endif
