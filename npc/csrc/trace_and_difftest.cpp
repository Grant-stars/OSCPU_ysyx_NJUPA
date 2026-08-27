#include "common.h"
char log_buf[128];

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

