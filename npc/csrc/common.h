#ifndef __COMMON_H__
#define __COMMON_H__
#include <stdint.h>
#include <stdlib.h>
#include  <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "include/debug.h"

#define CONFIG_MSIZE (1U<<30)
#define CONFIG_MBASE 0x80000000

typedef uint32_t word_t; 

//#define CONFIG_FTRACE
//#define CONFIG_DTRACE
//#define CONFIG_ITRACE


#endif
