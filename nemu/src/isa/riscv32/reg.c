/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include "local-include/reg.h"
#include <inttypes.h>
const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  for(int i =0;i<32;i++){
    printf("%-15s0x%-20"PRIX32"%-20"PRIu32"\n",regs[i], cpu.gpr[i], cpu.gpr[i]);
  }
  printf("%-15s0x%-20"PRIX32"0x%-20"PRIX32"\n","pc", cpu.pc, cpu.pc);
  
}

word_t isa_reg_str2val(const char *s, bool *success) {
  if(!strcmp(s,"0")){
    *success = true;
    return cpu.gpr[0];
  }
  else if(!strcmp(s,"pc")){
    *success = true;
    return cpu.pc;    
  }
  for(int i=1; i<32; i++){
    if(!strcmp(s,regs[i])){
      *success = true;
      return cpu.gpr[i];
    }
  }
  *success=false;
  return 0;
}
  
bool isa_reg_check(CPU_state *ref_r, vaddr_t pc){
	for(int i=0; i<32; i++){
		if(cpu.gpr[i]!=ref_r->gpr[i]){
			return false;
		}
	}	
	if(cpu.pc!=ref_r->pc){
		return false;
	}
	return true;
}


void regcpy(CPU_state* dut){
	for(int i=0; i<32; i++){
		dut->gpr[i] = cpu.gpr[i];	
	}
	dut->pc = cpu.pc;
}

void regset(CPU_state* dut){
	for(int i =0; i<32; i++){
		cpu.gpr[i]=dut->gpr[i];
	}
	cpu.pc = dut->pc;
}




