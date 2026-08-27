#include "common.h"
#include <elf.h>
void func_call(Elf32_Addr pc, Elf32_Addr dest);
void func_ret(Elf32_Addr pc, Elf32_Addr dest);
char log_buf[128];

#define ra 0x1
#define x0 0x0

enum jump_type{JUMP_NOP = 0, JUMP_JALR = 1, JUMP_JAL = 2};
void disasm(uint32_t pc, uint32_t instruction){
    char *p = log_buf;
    p += snprintf(p, sizeof(log_buf), FMT_WORD ":", pc);
    int ilen =4; 
    int j;
    uint8_t *inst = (uint8_t *)&instruction;
    for (j = ilen - 1; j >= 0; j --) {
      p += snprintf(p, 4, " %02x", inst[j]);
    }
    *p = ' ';
    p++;  
    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    disassemble(p, log_buf + sizeof(log_buf) - p,
      pc, (uint8_t *)&instruction, ilen);
}

void func_check(int jump, int rs1, int rd, uint32_t pc, uint32_t npc){
	if(jump==JUMP_JALR){
		if(rd == ra) func_call(pc, npc);	
		else if(rd == x0 && rs1 == ra) func_ret(pc, npc);	
	}	
	else if(jump==JUMP_JAL){
		if(rd == ra) func_call(pc, npc);	
	}
}
