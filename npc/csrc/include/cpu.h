#ifndef __CPU_H__
#define __CPU_H__

#include <stdint.h>

typedef struct CPU_state{
	uint32_t gpr[32];
	uint32_t pc;
}CPU_state;


void CPU_update();
void CPU_reset();
bool reg_check(CPU_state *ref_r, uint32_t pc);
void reg_display();


#endif
