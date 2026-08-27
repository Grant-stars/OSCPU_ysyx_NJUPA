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

typedef uint32_t word_t; 

#define FMT_WORD "0x%08" PRIx32

#define CONFIG_TRACE 1
#ifdef CONFIG_TRACE

//#define CONFIG_FTRACE
//#define CONFIG_DTRACE
#define CONFIG_MTRACE 1
#define CONFIG_ITRACE 1
//#define CONFIG_WATCHPOINT

#endif

#endif
